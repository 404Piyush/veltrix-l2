#!/bin/bash
set -e

echo "Running pre-flight chain integrity checks..."
# Verify rollup.json exists and is valid JSON
jq . configs/rollup.json > /dev/null

echo "Starting Veltrix Devnet with Monitoring..."
docker-compose -f ops/docker-compose.yml up -d

echo "Veltrix is running. Access Grafana at http://localhost:3000"
