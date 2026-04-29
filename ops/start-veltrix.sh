#!/bin/bash
set -e

echo "Starting Veltrix Devnet..."
docker-compose -f ops/docker-compose.yml up -d

echo "Veltrix is running. Verify services with 'docker-compose ps'."
