# Devnet Setup Guide

This guide details how to launch the Veltrix local devnet.

## Prerequisites
- Docker & Docker Compose
- Foundry

## Launching the Devnet
1. From the repository root, run: `./ops/start-veltrix.sh`
2. For a clean local chain, run: `./ops/start-veltrix.sh --reset`

The start script launches Anvil, deploys the local OP Stack L1 contracts when needed,
synchronizes the rollup L1 genesis hash, and starts `op-geth`, `op-node`,
`op-batcher`, and `op-proposer`.

## Verifying Services
- L1 (Anvil): `http://localhost:8545`
- L2 (Geth): `http://localhost:9545`
- Rollup RPC: `http://localhost:7545`

Run the bridge smoke test:

```bash
./ops/test-bridge-flow.sh
```

The smoke test verifies a native ETH deposit through `OptimismPortal` and a withdrawal
initiation through `L2ToL1MessagePasser`, then proves, resolves, and finalizes the
withdrawal on L1.

## Next Milestone

After the local bridge flow passes, the next step is Sepolia private testnet setup.
Start with:

```bash
./ops/check-sepolia-preflight.sh
```
