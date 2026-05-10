# Veltrix Public Testnet Checklist

Use this before posting public URLs or inviting testers.

## Public Endpoints

- RPC URL: `https://veltrix-rpc.404piyush.me`
- Explorer URL: `TODO: https://explorer.yourdomain.com`
- Bridge URL: `TODO: https://bridge.yourdomain.com`
- Faucet URL: `TODO: https://faucet.yourdomain.com`
- Status/Grafana URL: `TODO: private or public read-only dashboard`

## Chain Metadata

- Network name: `Veltrix Sepolia L2`
- Chain ID: `845320`
- Chain ID hex: `0xce608`
- Native currency: `VEL`
- Parent chain: `Sepolia`
- L1 chain ID: `11155111`
- Block time: `2s`
- Batch inbox: `0xff000000000000000000000000000000000ce608`

## User-Facing Apps

- Explorer app path: `/Users/piyushutkar/Desktop/block-explorer/client`
- Bridge app path: `/Users/piyushutkar/Desktop/veltrix-bridge`
- Explorer and bridge should deploy separately.
- Bridge is functional for deposit and withdrawal initiation.
- Bridge proof/finalize actions are still script-based and must be marked as a known limitation until added to UI.

## Contracts To Publish

- `OptimismPortalProxy`: `0x9d6954E55297f9ae78e5c0dc2353c18b31aeA0b3`
- `L1StandardBridgeProxy`: `0x138c79a5b92D31c8C48e9C8AAFFaAc06e732678A`
- `L1CrossDomainMessengerProxy`: `0xA657bC1DAFdf553D85944e3889Ed85156A777585`
- `SystemConfigProxy`: `0xfA2F9ad613A238EE2AD5D9307bE13a5003706Bfb`
- `DisputeGameFactoryProxy`: `0xEEFd9e073235CB75074403711c13B477822FdfC4`
- `L2ToL1MessagePasser`: `0x4200000000000000000000000000000000000016`

## Pre-Launch Verification

- `./ops/health-check.sh` shows Sepolia `l1_cursor_lag` near the normal head range.
- Sepolia `safe_l2` and `finalized_l2` continue advancing.
- Batcher logs show L1 batch submissions.
- Proposer logs show newer output roots and L1 confirmations.
- Explorer loads dashboard, block detail, transaction detail, and address detail.
- Bridge app loads with production env vars, not localhost URLs.
- MetaMask can add Veltrix L2 through the bridge app.
- Deposit works from Sepolia to Veltrix L2.
- Withdrawal initiation works from Veltrix L2.
- Withdrawal proof works through script.
- Withdrawal finalization works after dispute-game maturity.
- Reference withdrawal finalized in tx `0xeacca9d2e70560e4ebe972a8f09849628a0b1f0b49045c74a2ecb135ba30772f`.

## Known Limitations To Disclose

- Public RPC/domain is live, but the fresh DigitalOcean VPS still needs to finish first catch-up before public testing.
- Bridge UI currently handles deposit and withdrawal initiation only.
- Withdrawal proof and finalization are still script-driven.
- Faucet is not live yet.
- This is a testnet stack, not mainnet.
- Public monitoring should not expose secrets or admin controls.

## Launch Assets

- Screenshot checklist: `docs/screenshots/README.md`
- Contracts page: `docs/deployment/contracts.md`
- Operations runbook: `docs/ops/runbook.md`
- Bridge limitations: `docs/bridge/limitations.md`
- Current status: `STATUS_2026-05-04.md`
