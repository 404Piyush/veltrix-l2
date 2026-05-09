# Sepolia Private Testnet Preparation

This guide covers the next Veltrix milestone after the local devnet: preparing a Sepolia-backed private testnet.

## Required Inputs

Populate `ops/.env` with at least:

```bash
L1_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/<key>
L1_BEACON_URL=https://ethereum-sepolia-beacon-api.publicnode.com
L1_RUNTIME_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
L1_CHAIN_ID=11155111

DEPLOYER_PRIVATE_KEY=0x...
SEQUENCER_PRIVATE_KEY=0x...
BATCHER_PRIVATE_KEY=0x...
PROPOSER_PRIVATE_KEY=0x...
```

Use distinct funded keys for the batcher and proposer. Reusing one key for both causes L1 nonce collisions.

`L1_RUNTIME_RPC_URL` is optional but recommended. It lets the always-on stack use a separate
Sepolia RPC from the deployer RPC, which helps avoid rate-limit stalls during sequencing,
batching, and receipt polling.

## Preflight

Run:

```bash
./ops/check-sepolia-preflight.sh
```

The preflight verifies:

- required local tooling (`curl`, `jq`, `cast`, `forge`)
- Sepolia RPC reachability and chain ID
- Sepolia beacon API reachability
- operator addresses derived from the configured private keys
- batcher/proposer key separation
- presence of local JWT and P2P node key files

## Generate the Sepolia Deploy Config

The local `configs/deploy-config.json` is for Anvil and should not be reused as-is on Sepolia.

Generate a Sepolia-specific file with:

```bash
./ops/generate-sepolia-config.sh
```

This writes `configs/deploy-config.sepolia.json` from the upstream Sepolia devnet template and
fills in the current Veltrix values from `.env`.

For Sepolia, `systemConfigStartBlock` is intentionally generated as `0` so the contract records
the actual deployment block during initialization.

## Deploy the Bedrock L1 Contracts

Run:

```bash
./ops/deploy-sepolia-l1.sh
```

This writes `configs/l1-deployments.sepolia.json`.

## Generate L2 Artifacts

Run:

```bash
./ops/generate-sepolia-artifacts.sh
```

This writes:

- `configs/allocs-l2-sepolia.json`
- `configs/genesis.sepolia.json`
- `configs/rollup.sepolia.json`

The generator also enables Ecotone and Fjord at genesis for the private testnet. Without that,
L2 user transactions stay on the legacy fee path and can be priced incorrectly.

## Start the Sepolia-Backed Stack

Run:

```bash
./ops/start-sepolia-stack.sh
```

Use `--reset` to discard the local `op-geth` data volume and reinitialize from `genesis.sepolia.json`.

## Run the Sepolia Bridge Smoke Test

Run:

```bash
./ops/test-sepolia-bridge-flow.sh
```

This verifies:

- L1 -> L2 ETH deposit through `OptimismPortalProxy`
- deposit derivation into the local Sepolia-backed L2
- L2 -> L1 withdrawal initiation through `L2ToL1MessagePasser`

To attempt prove/finalize in the same flow:

```bash
FINALIZE_WITHDRAWAL=1 ./ops/test-sepolia-bridge-flow.sh
```

Sepolia-backed prove/finalize now uses [ops/finalize-sepolia-withdrawal.sh](/Users/piyushutkar/Desktop/Veltrix/ops/finalize-sepolia-withdrawal.sh).
It signs L1 transactions with the deployer key from `.env` and is safe to rerun. If the dispute game is not yet
resolvable, it reports the game status and the earliest approximate `resolveClaim(0)` time instead of reproving.

## What Comes Next

Once preflight passes, the remaining private testnet work is:

1. generate `configs/deploy-config.sepolia.json`
2. deploy the Bedrock L1 contracts to Sepolia with `./ops/deploy-sepolia-l1.sh`
3. save the resulting addresses as `configs/l1-deployments.sepolia.json`
4. generate Sepolia-specific rollup and genesis artifacts with `./ops/generate-sepolia-artifacts.sh`
5. start `op-node`, `op-batcher`, and `op-proposer` against Sepolia with `./ops/start-sepolia-stack.sh`
6. run Sepolia-backed bridge smoke tests

## Monitoring

After both local and Sepolia-backed stacks are running, start the local monitoring
profile:

```bash
./ops/start-monitoring.sh
```

For a quick read-only chain status check:

```bash
./ops/health-check.sh
```

## Current State

The local milestone is complete:

- L1 contract deployment to local Anvil
- local L2 sequencing, batching, and proposing
- L1 -> L2 ETH deposit
- L2 -> L1 withdrawal initiation
- withdrawal proof, dispute-game resolution, and finalization

The Sepolia-backed milestone is now complete through withdrawal initiation:

- Bedrock L1 contracts deployed to Sepolia
- Sepolia `allocs`, `genesis`, and `rollup` artifacts generated
- Sepolia-backed `op-geth`, `op-node`, `op-batcher`, and `op-proposer` runtime starts successfully
- Sepolia L1 -> L2 deposit confirmed into the local L2 execution layer
- Sepolia L2 -> L1 withdrawal initiation confirmed from the local L2 execution layer
- Sepolia withdrawal proving confirmed on L1, pending dispute-game clock expiry before resolve/finalize
