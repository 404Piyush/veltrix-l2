#!/bin/sh

if [ ! -d "/root/.ethereum/geth/chaindata" ]; then
    echo "Initializing Veltrix genesis..."
    geth --datadir /root/.ethereum --state.scheme=hash init /config/genesis.json
fi

echo "Starting op-geth..."
exec geth \
  --datadir /root/.ethereum \
  --state.scheme=hash \
  --syncmode=full \
  --gcmode=archive \
  --cache="${GETH_CACHE:-512}" \
  --networkid "${L2_CHAIN_ID:-42069}" \
  --nodiscover \
  --maxpeers=0 \
  --http \
  --http.addr=0.0.0.0 \
  --http.vhosts="*" \
  --http.api=eth,net,web3,debug,admin,engine \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.vhosts="*" \
  --authrpc.jwtsecret=/config/jwt.txt \
  --metrics \
  --metrics.addr=0.0.0.0 \
  --metrics.port=6060
