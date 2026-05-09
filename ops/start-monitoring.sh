#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

if docker compose version >/dev/null 2>&1; then
    COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE=(docker-compose)
else
    echo "Error: Docker Compose is not installed."
    exit 1
fi

for network in ops_default veltrix-sepolia_default; do
    if ! docker network inspect "$network" >/dev/null 2>&1; then
        echo "Error: missing Docker network '$network'."
        echo "Start the local and Sepolia stacks before monitoring:"
        echo "  ./ops/start-veltrix.sh"
        echo "  ./ops/start-sepolia-stack.sh"
        exit 1
    fi
done

COMPOSE_PROJECT_NAME=veltrix-monitoring "${COMPOSE[@]}" -f "$ROOT_DIR/ops/docker-compose.monitoring.yml" up -d

echo "Veltrix monitoring is running."
echo "Prometheus: http://localhost:9090"
echo "Grafana:    http://localhost:3001"
echo "Grafana default login: admin / veltrix"
