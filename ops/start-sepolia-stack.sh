#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
RESET=false
ENV_FILE=${ENV_FILE:-}

if [ "${1:-}" = "--reset" ]; then
    RESET=true
elif [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: ./ops/start-sepolia-stack.sh [--reset]"
    echo
    echo "  --reset   Stop the Sepolia-backed stack and remove Docker volumes before starting."
    exit 0
elif [ -n "${1:-}" ]; then
    echo "Error: Unknown argument '$1'"
    echo "Usage: ./ops/start-sepolia-stack.sh [--reset]"
    exit 1
fi

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

if [ -n "${L1_BEACON_RPC_URL:-}" ] && [ -z "${L1_BEACON_URL:-}" ]; then
    L1_BEACON_URL="$L1_BEACON_RPC_URL"
fi

L1_BEACON_URL=${L1_BEACON_URL:-https://ethereum-sepolia-beacon-api.publicnode.com}
L1_RUNTIME_RPC_URL=${L1_RUNTIME_RPC_URL:-${L1_RPC_URL:-https://ethereum-sepolia-rpc.publicnode.com}}

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

require_command jq
require_command curl

if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is installed, but the Docker daemon is not healthy."
    exit 1
fi

if docker compose version >/dev/null 2>&1; then
    COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE=(docker-compose)
else
    echo "Error: Docker Compose is not installed."
    exit 1
fi

require_env L1_RPC_URL
require_env L1_BEACON_URL
require_env L1_RUNTIME_RPC_URL
require_env BATCHER_PRIVATE_KEY
require_env PROPOSER_PRIVATE_KEY

if [ ! -f "$ROOT_DIR/configs/l1-deployments.sepolia.json" ]; then
    echo "Error: missing configs/l1-deployments.sepolia.json."
    echo "Run ./ops/deploy-sepolia-l1.sh first."
    exit 1
fi

if [ ! -f "$ROOT_DIR/configs/rollup.sepolia.json" ] || [ ! -f "$ROOT_DIR/configs/genesis.sepolia.json" ]; then
    "$ROOT_DIR/ops/generate-sepolia-artifacts.sh"
fi

export L2_CHAIN_ID
L2_CHAIN_ID=$(jq -r '.l2ChainID' "$ROOT_DIR/configs/deploy-config.sepolia.json")
export DGF_ADDRESS
DGF_ADDRESS=$(jq -r '.DisputeGameFactoryProxy' "$ROOT_DIR/configs/l1-deployments.sepolia.json")
export GAME_TYPE
GAME_TYPE=$(jq -r '.respectedGameType' "$ROOT_DIR/configs/deploy-config.sepolia.json")
export L1_BEACON_URL
export L1_RUNTIME_RPC_URL

if [ "$RESET" = true ]; then
    COMPOSE_PROJECT_NAME=veltrix-sepolia "${COMPOSE[@]}" -f "$ROOT_DIR/ops/docker-compose.sepolia.yml" down -v --remove-orphans
fi

COMPOSE_PROJECT_NAME=veltrix-sepolia "${COMPOSE[@]}" -f "$ROOT_DIR/ops/docker-compose.sepolia.yml" up -d

echo "Waiting for Sepolia-backed L2 RPC..."
for attempt in {1..45}; do
    if curl -fsS -X POST http://localhost:9546 \
        -H 'content-type: application/json' \
        --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' >/dev/null; then
        break
    fi

    if [ "$attempt" -eq 45 ]; then
        echo "Error: Sepolia-backed L2 RPC did not become ready in time."
        COMPOSE_PROJECT_NAME=veltrix-sepolia "${COMPOSE[@]}" -f "$ROOT_DIR/ops/docker-compose.sepolia.yml" logs --tail=80
        exit 1
    fi

    sleep 2
done

echo "Waiting for rollup RPC..."
for attempt in {1..45}; do
    if curl -fsS -X POST http://localhost:7546 \
        -H 'content-type: application/json' \
        --data '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' >/dev/null; then
        break
    fi

    if [ "$attempt" -eq 45 ]; then
        echo "Error: rollup RPC did not become ready in time."
        COMPOSE_PROJECT_NAME=veltrix-sepolia "${COMPOSE[@]}" -f "$ROOT_DIR/ops/docker-compose.sepolia.yml" logs --tail=80
        exit 1
    fi

    sleep 2
done

echo "Veltrix Sepolia-backed stack is running."
echo "L2 RPC: http://localhost:9546"
echo "Engine RPC: http://localhost:8552"
echo "Rollup RPC: http://localhost:7546"
