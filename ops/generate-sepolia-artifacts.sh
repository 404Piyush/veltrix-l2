#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
ENV_FILE=${ENV_FILE:-}
SEPOLIA_CONFIG=${SEPOLIA_CONFIG:-"$ROOT_DIR/configs/deploy-config.sepolia.json"}
SEPOLIA_DEPLOYMENTS=${SEPOLIA_DEPLOYMENTS:-"$ROOT_DIR/configs/l1-deployments.sepolia.json"}
OUT_ALLOCS=${OUT_ALLOCS:-"$ROOT_DIR/configs/allocs-l2-sepolia.json"}
OUT_GENESIS=${OUT_GENESIS:-"$ROOT_DIR/configs/genesis.sepolia.json"}
OUT_ROLLUP=${OUT_ROLLUP:-"$ROOT_DIR/configs/rollup.sepolia.json"}

load_env_file() {
    local path="$1"
    if [ -f "$path" ]; then
        # shellcheck disable=SC1090
        set -a
        . "$path"
        set +a
    fi
}

if [ -n "$ENV_FILE" ]; then
    load_env_file "$ENV_FILE"
else
    load_env_file "$ROOT_DIR/.env"
    load_env_file "$ROOT_DIR/ops/.env"
fi

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: required command '$1' is not installed."
        exit 1
    fi
}

require_env() {
    local name="$1"
    if [ -z "${!name:-}" ]; then
        echo "Error: required env var '$name' is not set."
        exit 1
    fi
}

require_command forge
require_command go
require_command jq
require_command cast

require_env L1_RPC_URL

if [ ! -f "$SEPOLIA_CONFIG" ]; then
    "$ROOT_DIR/ops/generate-sepolia-config.sh"
fi

if [ ! -f "$SEPOLIA_DEPLOYMENTS" ]; then
    echo "Error: missing $SEPOLIA_DEPLOYMENTS."
    echo "Run ./ops/deploy-sepolia-l1.sh first."
    exit 1
fi

mkdir -p "$ROOT_DIR/optimism-repo/packages/contracts-bedrock/deploy-config"
mkdir -p "$ROOT_DIR/optimism-repo/packages/contracts-bedrock/deployments"
cp "$SEPOLIA_CONFIG" "$ROOT_DIR/optimism-repo/packages/contracts-bedrock/deploy-config/veltrix-sepolia.json"
cp "$SEPOLIA_DEPLOYMENTS" "$ROOT_DIR/optimism-repo/packages/contracts-bedrock/deployments/veltrix-sepolia-deploy.json"

(
    cd "$ROOT_DIR/optimism-repo/packages/contracts-bedrock"
    CONTRACT_ADDRESSES_PATH=deployments/veltrix-sepolia-deploy.json \
        DEPLOY_CONFIG_PATH=deploy-config/veltrix-sepolia.json \
        STATE_DUMP_PATH=state-dump-sepolia.json \
        forge script scripts/L2Genesis.s.sol:L2Genesis --sig 'runWithStateDump()'
)

cp "$ROOT_DIR/optimism-repo/packages/contracts-bedrock/state-dump-sepolia.json" "$OUT_ALLOCS"

(
    cd "$ROOT_DIR/optimism-repo/op-node"
    go run cmd/main.go genesis l2 \
        --l1-rpc "$L1_RPC_URL" \
        --deploy-config ../packages/contracts-bedrock/deploy-config/veltrix-sepolia.json \
        --l2-allocs ../packages/contracts-bedrock/state-dump-sepolia.json \
        --l1-deployments ../packages/contracts-bedrock/deployments/veltrix-sepolia-deploy.json \
        --outfile.l2 "$OUT_GENESIS" \
        --outfile.rollup "$OUT_ROLLUP"
)

SYSTEM_CONFIG_PROXY=$(jq -r '.SystemConfigProxy' "$SEPOLIA_DEPLOYMENTS")
START_BLOCK=$(cast call --rpc-url "$L1_RPC_URL" "$SYSTEM_CONFIG_PROXY" 'startBlock()(uint256)' | awk '{print $1}')
START_BLOCK_HASH=$(cast block --json --rpc-url "$L1_RPC_URL" "$START_BLOCK" | jq -r '.hash')
EIP1559_ELASTICITY=$(jq -r '.eip1559Elasticity // 6' "$SEPOLIA_CONFIG")
EIP1559_DENOMINATOR=$(jq -r '.eip1559Denominator // 50' "$SEPOLIA_CONFIG")
EIP1559_DENOMINATOR_CANYON=$(jq -r '.eip1559DenominatorCanyon // 250' "$SEPOLIA_CONFIG")

tmp_file=$(mktemp)
jq \
    --arg hash "$START_BLOCK_HASH" \
    --argjson number "$START_BLOCK" \
    --argjson elasticity "$EIP1559_ELASTICITY" \
    --argjson denominator "$EIP1559_DENOMINATOR" \
    --argjson denominatorCanyon "$EIP1559_DENOMINATOR_CANYON" \
    '.genesis.l1.hash = $hash
    | .genesis.l1.number = $number
    | .chain_op_config = {
        eip1559Elasticity: $elasticity,
        eip1559Denominator: $denominator,
        eip1559DenominatorCanyon: $denominatorCanyon
      }' \
    "$OUT_ROLLUP" > "$tmp_file"
mv "$tmp_file" "$OUT_ROLLUP"

echo "Wrote $OUT_ALLOCS"
echo "Wrote $OUT_GENESIS"
echo "Wrote $OUT_ROLLUP"
