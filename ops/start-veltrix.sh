#!/bin/bash
set -e

RESET=false
if [ "${1:-}" = "--reset" ]; then
    RESET=true
elif [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: ./ops/start-veltrix.sh [--reset]"
    echo
    echo "  --reset   Stop the local devnet and remove Docker volumes before starting."
    exit 0
elif [ -n "${1:-}" ]; then
    echo "Error: Unknown argument '$1'"
    echo "Usage: ./ops/start-veltrix.sh [--reset]"
    exit 1
fi

# Ensure we are in the project root
if [ ! -d "ops" ]; then
    echo "Error: Please run this script from the Veltrix root directory (/Users/piyushutkar/Desktop/Veltrix)"
    exit 1
fi

echo "Running pre-flight chain integrity checks..."
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required to validate and synchronize rollup.json."
    exit 1
fi
jq . configs/rollup.json > /dev/null
export L1_GENESIS_TIMESTAMP
L1_GENESIS_TIMESTAMP=$(jq -r '.genesis.l2_time' configs/rollup.json)
MINER_PID=""

cleanup() {
    if [ -n "${MINER_PID:-}" ]; then
        kill "$MINER_PID" >/dev/null 2>&1 || true
        wait "$MINER_PID" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is installed, but the Docker daemon is not healthy."
    echo
    echo "Docker reports it cannot connect to docker.raw.sock. On macOS this usually means Docker Desktop"
    echo "is still starting, crashed, or needs a restart."
    echo
    echo "Fix:"
    echo "  1. Quit Docker Desktop completely."
    echo "  2. Open Docker Desktop again and wait until it says it is running."
    echo "  3. Verify with: docker version"
    echo "  4. Re-run: ./ops/start-veltrix.sh"
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

if [ "$RESET" = true ]; then
    echo "Resetting Veltrix local devnet volumes..."
    "${COMPOSE[@]}" -f ops/docker-compose.yml down -v --remove-orphans
fi

echo "Starting Veltrix L1..."
"${COMPOSE[@]}" -f ops/docker-compose.yml up -d l1

echo "Waiting for L1 RPC..."
for attempt in {1..30}; do
    if curl -fsS -X POST http://localhost:8545 \
        -H 'content-type: application/json' \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' >/dev/null; then
        break
    fi

    if [ "$attempt" -eq 30 ]; then
        echo "Error: L1 RPC did not become ready in time."
        exit 1
    fi

    sleep 1
done

L1_GENESIS_HASH=$(curl -fsS -X POST http://localhost:8545 \
    -H 'content-type: application/json' \
    --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x0",false],"id":1}' | jq -r '.result.hash')

if [ -z "$L1_GENESIS_HASH" ] || [ "$L1_GENESIS_HASH" = "null" ]; then
    echo "Error: Could not read L1 genesis hash."
    exit 1
fi

ROLLUP_L1_HASH=$(jq -r '.genesis.l1.hash' configs/rollup.json)
if [ "$ROLLUP_L1_HASH" != "$L1_GENESIS_HASH" ]; then
    echo "Synchronizing rollup.json L1 genesis hash..."
    tmp_file=$(mktemp)
    jq --arg hash "$L1_GENESIS_HASH" '.genesis.l1.hash = $hash | .genesis.l1.number = 0' configs/rollup.json > "$tmp_file"
    mv "$tmp_file" configs/rollup.json
fi

DISPUTE_GAME_FACTORY=$(jq -r '.DisputeGameFactoryProxy // empty' configs/l1-deployments.json)
if [ -z "$DISPUTE_GAME_FACTORY" ]; then
    echo "Error: configs/l1-deployments.json is missing DisputeGameFactoryProxy."
    exit 1
fi

DISPUTE_GAME_FACTORY_CODE=$(curl -fsS -X POST http://localhost:8545 \
    -H 'content-type: application/json' \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getCode\",\"params\":[\"$DISPUTE_GAME_FACTORY\",\"latest\"],\"id\":1}" | jq -r '.result')

if [ "$DISPUTE_GAME_FACTORY_CODE" = "0x" ] || [ -z "$DISPUTE_GAME_FACTORY_CODE" ] || [ "$DISPUTE_GAME_FACTORY_CODE" = "null" ]; then
    if ! command -v forge >/dev/null 2>&1; then
        echo "Error: L1 contracts are not deployed and forge is required to deploy them."
        exit 1
    fi

    if [ ! -d "optimism-repo/packages/contracts-bedrock" ]; then
        echo "Error: optimism-repo/packages/contracts-bedrock is required to deploy L1 contracts."
        exit 1
    fi

    echo "Deploying Veltrix L1 contracts..."
    (
        cd optimism-repo/packages/contracts-bedrock
        mkdir -p deploy-config deployments
        cp ../../../configs/deploy-config.json deploy-config/veltrix-local.json
    )

    (
        while true; do
            curl -fsS -X POST http://localhost:8545 \
                -H 'content-type: application/json' \
                --data '{"jsonrpc":"2.0","method":"anvil_mine","params":["0x1"],"id":1}' >/dev/null 2>&1 || true
            sleep 1
        done
    ) &
    MINER_PID=$!

    (
        cd optimism-repo/packages/contracts-bedrock
        DEPLOYMENT_OUTFILE=deployments/veltrix-local-deploy.json \
            DEPLOY_CONFIG_PATH=deploy-config/veltrix-local.json \
            forge script scripts/deploy/Deploy.s.sol:Deploy \
                --rpc-url http://localhost:8545 \
                --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
                --broadcast \
                --slow \
                --non-interactive \
                -vv
    )

    cleanup
    MINER_PID=""
    cp optimism-repo/packages/contracts-bedrock/deployments/veltrix-local-deploy.json configs/l1-deployments.json
fi

echo "Starting Veltrix L2 services..."
COMPOSE_PROFILES=proposer "${COMPOSE[@]}" -f ops/docker-compose.yml up -d op-geth op-node op-batcher op-proposer

echo "Veltrix is running."
echo "L2 RPC: http://localhost:9545"
echo "L1 RPC (Anvil): http://localhost:8545"
echo "Rollup RPC: http://localhost:7545"
