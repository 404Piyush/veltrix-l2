#!/bin/bash
set -e

# Base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPS_DIR="$BASE_DIR/ops"
CONFIGS_DIR="$BASE_DIR/configs"

echo "🚀 Initializing Veltrix L2 Local Devnet..."

# 1. Generate JWT secret if it doesn't exist
if [ ! -f "$OPS_DIR/jwt.txt" ]; then
    echo "🔑 Generating JWT secret..."
    openssl rand -hex 32 > "$OPS_DIR/jwt.txt"
fi

# 2. Start the Mock L1 (Anvil)
echo "⛓️ Starting Mock L1 (Anvil)..."
docker compose -f "$OPS_DIR/docker-compose.yml" up -d l1

echo "⏳ Waiting for L1 to be ready..."
COUNT=0
until curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545 > /dev/null; do
    sleep 1
    COUNT=$((COUNT+1))
    if [ $((COUNT % 5)) -eq 0 ]; then
        echo "   ... still waiting ($COUNT seconds)"
    fi
    if [ $COUNT -gt 30 ]; then
        echo "❌ L1 failed to start in 30 seconds. Checking logs..."
        docker logs ops_l1_1
        exit 1
    fi
done
echo "✅ L1 is online."

# 3. Start the rest of the stack (op-geth entrypoint handles genesis init)
echo "🏗️ Starting Veltrix L2 stack..."
docker compose -f "$OPS_DIR/docker-compose.yml" up -d

echo "🎉 Veltrix L2 is starting up!"
echo "📍 L1 RPC: http://localhost:8545"
echo "📍 L2 RPC: http://localhost:9545"
echo "📍 Rollup RPC: http://localhost:7545"
echo "🔍 Use 'docker compose -f ops/docker-compose.yml logs -f' to watch the logs."
