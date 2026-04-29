# Devnet Setup Guide

This guide details how to launch the Veltrix local devnet.

## Prerequisites
- Docker & Docker Compose
- Foundry

## Launching the Devnet
1. Navigate to the `ops/` directory.
2. Ensure `jwt.txt` is configured with a 32-byte secret (64 hex characters).
3. Run: `docker-compose up -d`

## Verifying Services
- L1 (Anvil): `http://localhost:8545`
- L2 (Geth): `http://localhost:9545`
