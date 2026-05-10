# Veltrix Infrastructure - Developer Handover

## Current State
- Chain name: `Veltrix Sepolia L2`
- L2 chain ID: `845320` (`0xce608`)
- L1 parent: `Ethereum Sepolia`
- Status: live on VPS `159.223.145.63`
- Native token label: `VEL`
- Supply model: native gas token metadata, not a separate ERC-20 with a fixed `totalSupply()`

## Done
1. Migrated the network from `0xa455` to `0xce608`.
2. Redeployed the OP Stack L1 contracts on Sepolia for the new chain ID.
3. Regenerated genesis, deploy, and rollup artifacts for the `845320 / 0xce608` network.
4. Funded the main operator accounts on L2:
   - Sequencer: `1.0 VEL`
   - Batcher: `1.0 VEL`
   - Proposer: `1.0 VEL`
   - Faucet: `0.5 VEL`
5. Added `ops/report-native-supply.mjs` to document the genesis-side supply model.
6. Confirmed the explorer indexer is running on the VPS.

## Live Endpoints
- RPC: `https://veltrix-rpc.404piyush.me`
- Explorer: `https://veltrix-explorer.404piyush.me`
- Explorer indexer: `https://veltrix-rpc.404piyush.me/explorer-api`

## Key Files
- `configs/l1-deployments.sepolia.json`: current proxy addresses on Sepolia
- `configs/genesis.sepolia.json`: source of truth for L2 state
- `ops/start-veltrix.sh`: local devnet recovery and start script
- `ops/report-native-supply.mjs`: reports genesis native alloc totals and explains the `VEL` supply model

## VPS Management
SSH access: `ssh -i ~/.ssh/veltrix_do_ed25519 root@159.223.145.63`
Services:
- `veltrix-sepolia.service`: main L2 stack
- `veltrix-explorer-indexer.service`: explorer indexer

## Remaining
- Keep monitoring proposer output roots on Sepolia L1.
- Keep an eye on rollup catch-up and finalization timing.
- Re-run the bridge and proposer checks if the safe head stalls again.
