#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
ENV_FILE=${ENV_FILE:-}
EXPECTED_CHAIN_ID=${L1_CHAIN_ID:-11155111}

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

if [ -n "${L1_BEACON_RPC_URL:-}" ] && [ -z "${L1_BEACON_URL:-}" ]; then
    L1_BEACON_URL="$L1_BEACON_RPC_URL"
fi

L1_BEACON_URL=${L1_BEACON_URL:-https://ethereum-sepolia-beacon-api.publicnode.com}

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

address_for_key() {
    cast wallet address --private-key "$1"
}

balance_for_address() {
    cast balance --rpc-url "$L1_RPC_URL" --ether "$1"
}

require_command curl
require_command jq
require_command cast
require_command forge

require_env L1_RPC_URL
require_env L1_BEACON_URL
require_env DEPLOYER_PRIVATE_KEY

echo "Checking Sepolia RPC..."
ACTUAL_CHAIN_ID=$(cast chain-id --rpc-url "$L1_RPC_URL")
if [ "$ACTUAL_CHAIN_ID" != "$EXPECTED_CHAIN_ID" ]; then
    echo "Error: L1 RPC chain ID is $ACTUAL_CHAIN_ID, expected $EXPECTED_CHAIN_ID."
    exit 1
fi

LATEST_BLOCK=$(cast block-number --rpc-url "$L1_RPC_URL")
echo "Sepolia RPC ok: chain-id=$ACTUAL_CHAIN_ID latest-block=$LATEST_BLOCK"

echo "Checking Sepolia beacon API..."
BEACON_GENESIS=$(curl -fsS "$L1_BEACON_URL/eth/v1/beacon/genesis" | jq -r '.data.genesis_validators_root // empty')
if [ -z "$BEACON_GENESIS" ]; then
    echo "Error: could not read Sepolia beacon genesis from $L1_BEACON_URL."
    exit 1
fi
echo "Sepolia beacon ok: genesis_validators_root=$BEACON_GENESIS"

DEPLOYER_ADDRESS=$(address_for_key "$DEPLOYER_PRIVATE_KEY")

echo "Checking operator balances..."
printf '  deployer  %s  %s ETH\n' "$DEPLOYER_ADDRESS" "$(balance_for_address "$DEPLOYER_ADDRESS")"

if [ -n "${SEQUENCER_PRIVATE_KEY:-}" ]; then
    SEQUENCER_ADDRESS=$(address_for_key "$SEQUENCER_PRIVATE_KEY")
    printf '  sequencer %s  %s ETH\n' "$SEQUENCER_ADDRESS" "$(balance_for_address "$SEQUENCER_ADDRESS")"
else
    echo "  sequencer <missing>  skipped"
fi

if [ -n "${BATCHER_PRIVATE_KEY:-}" ]; then
    BATCHER_ADDRESS=$(address_for_key "$BATCHER_PRIVATE_KEY")
    printf '  batcher   %s  %s ETH\n' "$BATCHER_ADDRESS" "$(balance_for_address "$BATCHER_ADDRESS")"
else
    BATCHER_ADDRESS=""
    echo "  batcher   <missing>  skipped"
fi

if [ -n "${PROPOSER_PRIVATE_KEY:-}" ]; then
    PROPOSER_ADDRESS=$(address_for_key "$PROPOSER_PRIVATE_KEY")
    printf '  proposer  %s  %s ETH\n' "$PROPOSER_ADDRESS" "$(balance_for_address "$PROPOSER_ADDRESS")"
else
    PROPOSER_ADDRESS=""
    echo "  proposer  <missing>  skipped"
fi

if [ -n "$BATCHER_ADDRESS" ] && [ -n "$PROPOSER_ADDRESS" ] && [ "$BATCHER_ADDRESS" = "$PROPOSER_ADDRESS" ]; then
    echo "Error: BATCHER_PRIVATE_KEY and PROPOSER_PRIVATE_KEY resolve to the same address."
    echo "Use distinct L1-funded keys to avoid nonce collisions."
    exit 1
fi

JWT_PATH=${JWT_PATH:-"$ROOT_DIR/ops/jwt.txt"}
P2P_KEY_PATH=${P2P_KEY_PATH:-"$ROOT_DIR/ops/p2p-node-key.txt"}

if [ ! -f "$JWT_PATH" ]; then
    echo "Error: JWT secret file not found at $JWT_PATH."
    exit 1
fi

if [ ! -f "$P2P_KEY_PATH" ]; then
    echo "Error: P2P node key file not found at $P2P_KEY_PATH."
    exit 1
fi

echo
echo "Sepolia preflight passed."
echo "Next step: deploy L1 contracts to Sepolia, write addresses to configs/l1-deployments.sepolia.json,"
echo "then generate Sepolia-specific rollup/genesis configs for op-node, op-batcher, and op-proposer."
