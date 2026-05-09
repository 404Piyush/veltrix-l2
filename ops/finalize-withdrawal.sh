#!/bin/bash
set -euo pipefail

L1_RPC=${L1_RPC:-http://localhost:8545}
L2_RPC=${L2_RPC:-http://localhost:9545}
L1_DEPLOYMENTS=${L1_DEPLOYMENTS:-/Users/piyushutkar/Desktop/Veltrix/configs/l1-deployments.json}
FINALIZER_FROM=${FINALIZER_FROM:-0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC}
GO_BIN=${GO_BIN:-/opt/homebrew/bin/go}

if [ $# -ne 1 ]; then
    echo "Usage: ./ops/finalize-withdrawal.sh <l2-withdrawal-tx-hash>"
    exit 1
fi

if [ ! -f "$L1_DEPLOYMENTS" ]; then
    echo "Error: missing $L1_DEPLOYMENTS."
    exit 1
fi

if [ ! -x "$GO_BIN" ]; then
    echo "Error: go binary not found at $GO_BIN."
    exit 1
fi

cd /Users/piyushutkar/Desktop/Veltrix/optimism-repo

"$GO_BIN" run ./op-chain-ops/cmd/veltrix-withdrawal \
    --l1-rpc "$L1_RPC" \
    --l2-rpc "$L2_RPC" \
    --deployments "$L1_DEPLOYMENTS" \
    --withdrawal-tx "$1" \
    --from "$FINALIZER_FROM"
