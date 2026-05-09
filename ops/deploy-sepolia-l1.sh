#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
ENV_FILE=${ENV_FILE:-}
SEPOLIA_CONFIG=${SEPOLIA_CONFIG:-"$ROOT_DIR/configs/deploy-config.sepolia.json"}
SEPOLIA_DEPLOYMENTS=${SEPOLIA_DEPLOYMENTS:-"$ROOT_DIR/configs/l1-deployments.sepolia.json"}
IMPL_SALT=${IMPL_SALT:-veltrix-sepolia-42069}

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

if [ -n "${PRIVATE_KEY:-}" ] && [ -z "${DEPLOYER_PRIVATE_KEY:-}" ]; then
    DEPLOYER_PRIVATE_KEY="$PRIVATE_KEY"
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
require_command jq

require_env L1_RPC_URL
require_env DEPLOYER_PRIVATE_KEY

if [ ! -f "$SEPOLIA_CONFIG" ]; then
    "$ROOT_DIR/ops/generate-sepolia-config.sh"
fi

mkdir -p "$ROOT_DIR/optimism-repo/packages/contracts-bedrock/deploy-config"
mkdir -p "$ROOT_DIR/optimism-repo/packages/contracts-bedrock/deployments"
cp "$SEPOLIA_CONFIG" "$ROOT_DIR/optimism-repo/packages/contracts-bedrock/deploy-config/veltrix-sepolia.json"

(
    cd "$ROOT_DIR/optimism-repo/packages/contracts-bedrock"
    DEPLOYMENT_OUTFILE=deployments/veltrix-sepolia-deploy.json \
        DEPLOY_CONFIG_PATH=deploy-config/veltrix-sepolia.json \
        IMPL_SALT="$IMPL_SALT" \
        forge script scripts/deploy/Deploy.s.sol:Deploy \
            --rpc-url "$L1_RPC_URL" \
            --private-key "$DEPLOYER_PRIVATE_KEY" \
            --broadcast \
            --slow \
            --non-interactive \
            -vv
)

cp "$ROOT_DIR/optimism-repo/packages/contracts-bedrock/deployments/veltrix-sepolia-deploy.json" "$SEPOLIA_DEPLOYMENTS"
echo "Wrote $SEPOLIA_DEPLOYMENTS"
