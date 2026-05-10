# Veltrix Infrastructure - Developer Handover

## 🏗️ Core Infrastructure State
- **Chain Name:** Veltrix Sepolia L2
- **L2 Chain ID:** `845320` (`0xce608`)
- **L1 Parent:** Ethereum Sepolia
- **Status:** Migrated & Live on VPS (`159.223.145.63`).
- **Native Token Label:** `VEL`
- **Supply Model:** Native L2 gas token metadata, not a separate ERC-20 with a fixed `totalSupply()`.

## 🛠️ Recent Changes
1. **Chain Migration:** Successfully moved from `0xa455` to `0xce608`.
2. **L1 Redeploy:** All OP Stack L1 contracts (Portal, Bridge, etc.) redeployed on Sepolia for the new Chain ID.
3. **Artifact Sync:** Regenerated all genesis and rollup configs for the `845320 / 0xce608` network.
4. **Account Funding (L2):** 
   - Sequencer: 1.0 VEL
   - Batcher: 1.0 VEL
   - Proposer: 1.0 VEL
   - Faucet: 0.5 VEL
5. **Supply Clarification:** The repo does not define a standalone `VEL` ERC-20. The checked Sepolia genesis alloc totals only `256 wei`, so any meaningful circulating native balance comes from bridge deposits/runtime balances rather than a fixed token mint.

## 📂 Key Files
- `configs/l1-deployments.sepolia.json`: Current proxy addresses on Sepolia.
- `configs/genesis.sepolia.json`: The source of truth for the L2 state.
- `ops/start-veltrix.sh`: Automation for local devnet testing.
- `ops/report-native-supply.mjs`: Reports genesis native alloc totals and explains the `VEL` supply model.

## 🚀 VPS Management
SSH Access: `ssh -i ~/.ssh/veltrix_do_ed25519 root@159.223.145.63`
Services:
- `veltrix-sepolia.service`: Main L2 stack (docker-compose managed).
- `veltrix-explorer-indexer.service`: SQLite indexer for the explorer.

## 🚧 Next for Dev
- Monitor L2 block production at `https://veltrix-rpc.404piyush.me`.
- Ensure the Proposer is successfully posting output roots to Sepolia L1.
