#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
ENV_FILE=${ENV_FILE:-}
CALLER_L1_RPC="${L1_RPC-}"
CALLER_L2_RPC="${L2_RPC-}"
CALLER_L1_DEPLOYMENTS="${L1_DEPLOYMENTS-}"
CALLER_GO_BIN="${GO_BIN-}"
CALLER_RESOLVE_WAIT_TIMEOUT="${RESOLVE_WAIT_TIMEOUT-}"
CALLER_WITHDRAWAL_CHECK_TIMEOUT="${WITHDRAWAL_CHECK_TIMEOUT-}"
L1_RPC=${L1_RPC:-}
L2_RPC=${L2_RPC:-http://localhost:9546}
L1_DEPLOYMENTS=${L1_DEPLOYMENTS:-"$ROOT_DIR/configs/l1-deployments.sepolia.json"}
GO_BIN=${GO_BIN:-$(command -v go || true)}
RESOLVE_WAIT_TIMEOUT=${RESOLVE_WAIT_TIMEOUT:-30s}
WITHDRAWAL_CHECK_TIMEOUT=${WITHDRAWAL_CHECK_TIMEOUT:-2m}

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

L1_RPC=${CALLER_L1_RPC:-${L1_RPC:-}}
L2_RPC=${CALLER_L2_RPC:-${L2_RPC:-http://localhost:9546}}
L1_DEPLOYMENTS=${CALLER_L1_DEPLOYMENTS:-${L1_DEPLOYMENTS:-"$ROOT_DIR/configs/l1-deployments.sepolia.json"}}
GO_BIN=${CALLER_GO_BIN:-${GO_BIN:-$(command -v go || true)}}
RESOLVE_WAIT_TIMEOUT=${CALLER_RESOLVE_WAIT_TIMEOUT:-${RESOLVE_WAIT_TIMEOUT:-30s}}
WITHDRAWAL_CHECK_TIMEOUT=${CALLER_WITHDRAWAL_CHECK_TIMEOUT:-${WITHDRAWAL_CHECK_TIMEOUT:-2m}}

if [ $# -ne 1 ]; then
    echo "Usage: ./ops/finalize-sepolia-withdrawal.sh <l2-withdrawal-tx-hash>"
    exit 1
fi

L1_RPC=${L1_RPC:-${L1_RPC_URL:-}}
FINALIZER_PRIVATE_KEY=${FINALIZER_PRIVATE_KEY:-${DEPLOYER_PRIVATE_KEY:-${PRIVATE_KEY:-}}}

if [ -z "$L1_RPC" ]; then
    echo "Error: set L1_RPC or L1_RPC_URL."
    exit 1
fi

if [ -z "$FINALIZER_PRIVATE_KEY" ]; then
    echo "Error: set FINALIZER_PRIVATE_KEY, DEPLOYER_PRIVATE_KEY, or PRIVATE_KEY."
    exit 1
fi

if [ ! -f "$L1_DEPLOYMENTS" ]; then
    echo "Error: missing $L1_DEPLOYMENTS."
    exit 1
fi

if [ -z "$GO_BIN" ] || [ ! -x "$GO_BIN" ]; then
    echo "Error: go binary not found."
    exit 1
fi

cd "$ROOT_DIR/optimism-repo"

"$GO_BIN" run ./op-chain-ops/cmd/veltrix-withdrawal \
    --l1-rpc "$L1_RPC" \
    --l2-rpc "$L2_RPC" \
    --deployments "$L1_DEPLOYMENTS" \
    --withdrawal-tx "$1" \
    --private-key "$FINALIZER_PRIVATE_KEY" \
    --resolve-wait-timeout "$RESOLVE_WAIT_TIMEOUT" \
    --withdrawal-check-timeout "$WITHDRAWAL_CHECK_TIMEOUT"
