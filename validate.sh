#!/bin/bash
echo "--- L2 RPC Status ---"
curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:9545
echo ""
echo "--- Backend API Status ---"
curl -s http://localhost:4000/api/latest-blocks
echo ""
echo "--- Frontend Status ---"
curl -s http://localhost:5173/ | grep -q "Veltrix" && echo "UI Reachable" || echo "UI Unreachable"
