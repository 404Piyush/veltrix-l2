#!/bin/bash
set -euo pipefail

rpc() {
    local url="$1"
    local method="$2"
    curl -fsS -X POST "$url" \
        -H 'content-type: application/json' \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":[],\"id\":1}"
}

hex_to_dec() {
    local value="${1#0x}"
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "n/a"
        return
    fi
    echo $((16#$value))
}

print_chain() {
    local name="$1"
    local l2_rpc="$2"
    local rollup_rpc="$3"

    local chain_id_hex block_hex sync unsafe safe finalized lag current_l1 head_l1 l1_lag
    if ! rpc "$l2_rpc" eth_chainId >/dev/null 2>&1 || ! rpc "$rollup_rpc" optimism_syncStatus >/dev/null 2>&1; then
        printf "%-16s unavailable l2_rpc=%s rollup_rpc=%s\n" "$name" "$l2_rpc" "$rollup_rpc"
        return
    fi

    chain_id_hex=$(rpc "$l2_rpc" eth_chainId | jq -r '.result')
    block_hex=$(rpc "$l2_rpc" eth_blockNumber | jq -r '.result')
    sync=$(rpc "$rollup_rpc" optimism_syncStatus)

    unsafe=$(echo "$sync" | jq -r '.result.unsafe_l2.number // "n/a"')
    safe=$(echo "$sync" | jq -r '.result.safe_l2.number // "n/a"')
    finalized=$(echo "$sync" | jq -r '.result.finalized_l2.number // "n/a"')
    current_l1=$(echo "$sync" | jq -r '.result.current_l1.number // "n/a"')
    head_l1=$(echo "$sync" | jq -r '.result.head_l1.number // "n/a"')

    if [ "$unsafe" != "n/a" ] && [ "$safe" != "n/a" ]; then
        lag=$((unsafe - safe))
    else
        lag="n/a"
    fi

    if [ "$current_l1" != "n/a" ] && [ "$head_l1" != "n/a" ]; then
        l1_lag=$((head_l1 - current_l1))
        if [ "$l1_lag" -lt 0 ]; then
            l1_lag=0
        fi
    else
        l1_lag="n/a"
    fi

    printf "%-16s chain=%-8s head=%-8s unsafe=%-8s safe=%-8s finalized=%-8s unsafe_safe_lag=%-8s l1_cursor_lag=%s\n" \
        "$name" \
        "$(hex_to_dec "$chain_id_hex")" \
        "$(hex_to_dec "$block_hex")" \
        "$unsafe" \
        "$safe" \
        "$finalized" \
        "$lag" \
        "$l1_lag"
}

print_chain "local-devnet" "http://127.0.0.1:9545" "http://127.0.0.1:7545"
print_chain "sepolia" "http://127.0.0.1:9546" "http://127.0.0.1:7546"
