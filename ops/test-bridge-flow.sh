#!/bin/bash
set -euo pipefail

L1_RPC=${L1_RPC:-http://localhost:8545}
L2_RPC=${L2_RPC:-http://localhost:9545}
L1_DEPLOYMENTS=${L1_DEPLOYMENTS:-configs/l1-deployments.json}

DEPOSIT_FROM=${DEPOSIT_FROM:-0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC}
DEPOSIT_TO=${DEPOSIT_TO:-0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC}
WITHDRAW_TO=${WITHDRAW_TO:-0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266}

DEPOSIT_AMOUNT_WEI=${DEPOSIT_AMOUNT_WEI:-10000000000000000}
WITHDRAW_AMOUNT_WEI=${WITHDRAW_AMOUNT_WEI:-1000000000000000}
BRIDGE_GAS_LIMIT=${BRIDGE_GAS_LIMIT:-100000}
WITHDRAWER_PRIVATE_KEY=${WITHDRAWER_PRIVATE_KEY:-0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80}
FINALIZE_WITHDRAWAL=${FINALIZE_WITHDRAWAL:-1}

L2_TO_L1_MESSAGE_PASSER=0x4200000000000000000000000000000000000016
TRANSACTION_DEPOSITED_TOPIC=0xb3813568d9991fc951961fcb4c784893574240a28925604d09fc577c55bb7c32
MESSAGE_PASSED_TOPIC=0x02a52367d10742d8032712c1bb8e0144ff1ec5ffda1ed7d70bb05a2744955054

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: $1 is required."
        exit 1
    fi
}

rpc_ready() {
    local rpc=$1
    curl -fsS -X POST "$rpc" \
        -H 'content-type: application/json' \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' >/dev/null
}

wait_for_rpc() {
    local name=$1
    local rpc=$2

    for attempt in {1..30}; do
        if rpc_ready "$rpc"; then
            return
        fi
        sleep 1
    done

    echo "Error: $name RPC is not ready at $rpc."
    exit 1
}

wait_for_balance_change() {
    local address=$1
    local before=$2

    for attempt in {1..60}; do
        local after
        after=$(cast balance --rpc-url "$L2_RPC" "$address")
        if [ "$after" != "$before" ]; then
            echo "$after"
            return
        fi
        sleep 2
    done

    echo "Error: L2 balance for $address did not change after deposit." >&2
    exit 1
}

receipt_has_topic() {
    local receipt=$1
    local topic=$2
    echo "$receipt" | jq -e --arg topic "$topic" '.logs[]?.topics[0] == $topic' >/dev/null
}

require_command cast
require_command curl
require_command jq
require_command go

if [ ! -f "$L1_DEPLOYMENTS" ]; then
    echo "Error: missing $L1_DEPLOYMENTS."
    exit 1
fi

wait_for_rpc L1 "$L1_RPC"
wait_for_rpc L2 "$L2_RPC"

OPTIMISM_PORTAL_PROXY=$(jq -r '.OptimismPortalProxy // empty' "$L1_DEPLOYMENTS")
if [ -z "$OPTIMISM_PORTAL_PROXY" ]; then
    echo "Error: $L1_DEPLOYMENTS is missing OptimismPortalProxy."
    exit 1
fi

portal_code=$(cast code --rpc-url "$L1_RPC" "$OPTIMISM_PORTAL_PROXY")
if [ "$portal_code" = "0x" ]; then
    echo "Error: no OptimismPortal code at $OPTIMISM_PORTAL_PROXY on L1."
    exit 1
fi

echo "Testing L1 -> L2 deposit..."
deposit_before=$(cast balance --rpc-url "$L2_RPC" "$DEPOSIT_TO")
deposit_receipt=$(cast send \
    --rpc-url "$L1_RPC" \
    --unlocked \
    --from "$DEPOSIT_FROM" \
    "$OPTIMISM_PORTAL_PROXY" \
    'depositTransaction(address,uint256,uint64,bool,bytes)' \
    "$DEPOSIT_TO" \
    "$DEPOSIT_AMOUNT_WEI" \
    "$BRIDGE_GAS_LIMIT" \
    false \
    0x \
    --value "$DEPOSIT_AMOUNT_WEI" \
    --json)

if [ "$(echo "$deposit_receipt" | jq -r '.status')" != "0x1" ]; then
    echo "Error: deposit transaction failed."
    echo "$deposit_receipt" | jq .
    exit 1
fi

if ! receipt_has_topic "$deposit_receipt" "$TRANSACTION_DEPOSITED_TOPIC"; then
    echo "Error: deposit receipt did not include TransactionDeposited."
    echo "$deposit_receipt" | jq .
    exit 1
fi

deposit_after=$(wait_for_balance_change "$DEPOSIT_TO" "$deposit_before")
deposit_tx=$(echo "$deposit_receipt" | jq -r '.transactionHash')
echo "Deposit ok: $deposit_tx"
echo "L2 balance changed: $deposit_before -> $deposit_after"

echo "Testing L2 -> L1 withdrawal initiation..."
withdraw_receipt=$(cast send \
    --rpc-url "$L2_RPC" \
    --private-key "$WITHDRAWER_PRIVATE_KEY" \
    "$L2_TO_L1_MESSAGE_PASSER" \
    'initiateWithdrawal(address,uint256,bytes)' \
    "$WITHDRAW_TO" \
    "$BRIDGE_GAS_LIMIT" \
    0x \
    --value "$WITHDRAW_AMOUNT_WEI" \
    --json)

if [ "$(echo "$withdraw_receipt" | jq -r '.status')" != "0x1" ]; then
    echo "Error: withdrawal initiation failed."
    echo "$withdraw_receipt" | jq .
    exit 1
fi

if ! receipt_has_topic "$withdraw_receipt" "$MESSAGE_PASSED_TOPIC"; then
    echo "Error: withdrawal receipt did not include MessagePassed."
    echo "$withdraw_receipt" | jq .
    exit 1
fi

withdraw_tx=$(echo "$withdraw_receipt" | jq -r '.transactionHash')
withdrawal_data=$(echo "$withdraw_receipt" | jq -r ".logs[] | select(.topics[0] == \"$MESSAGE_PASSED_TOPIC\") | .data" | head -1)
withdrawal_hash="0x$(echo "${withdrawal_data#0x}" | cut -c193-256)"
echo "Withdrawal initiated: $withdraw_tx"
echo "Withdrawal hash: $withdrawal_hash"

if [ "$FINALIZE_WITHDRAWAL" = "1" ]; then
    echo "Testing withdrawal proof and finalization..."
    ./ops/finalize-withdrawal.sh "$withdraw_tx"
fi

echo "Bridge smoke test passed."
