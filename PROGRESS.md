# Veltrix Progress

Last updated: 2026-05-05

## Current Status

Veltrix is a Sepolia-backed OP Stack L2 with local monitoring, a custom explorer, validated deposit flow, validated withdrawal initiation/proof flow, a standalone bridge frontend prototype, and a public HTTPS RPC endpoint on DigitalOcean.

## Functional

- Local OP Stack devnet runs with L1, L2 execution, op-node, batcher, proposer, and bridge smoke tests.
- Sepolia-backed stack runs with chain ID `42069`.
- Sepolia derivation caught up from historical lag; `l1_cursor_lag` reached the normal near-head range around `4-5`.
- `safe_l2` advanced well past the original blocker at `13268`.
- Proposer no longer retries only the stale duplicate output. It publishes and confirms newer output roots after node sync.
- Monitoring is available through Prometheus and Grafana.
- Custom block explorer exists as a separate frontend in `/Users/piyushutkar/Desktop/block-explorer/client`.
- Standalone bridge frontend now exists in `/Users/piyushutkar/Desktop/veltrix-bridge`.
- Bridge frontend is marked functional for the first user-facing deposit/withdraw milestone.
- Bridge UI polish is intentionally deferred; the current focus was wiring real wallet actions and keeping it separate from the explorer.
- DigitalOcean VPS is configured for the Sepolia stack with Docker, 4GB swap, log rotation, and `veltrix-sepolia.service`.
- Public RPC is live at `https://veltrix-rpc.404piyush.me`.
- Public RPC returns chain ID `0xa455` for Veltrix chain `42069`.
- Raw Docker RPC ports are bound to localhost only; Nginx exposes HTTPS on `443`.

## Bridge Validation

- Sepolia L1 to Veltrix L2 deposit was validated manually after waiting for the L1 safe cursor to cross the deposit block.
- Deposit tx observed: `0x0df568942fc840afe9e3a1df8bb917b67122191eb84e056225621e2c92217636`.
- Deposit block observed: `10787344`.
- L2 balance increased from `1388436520669979` to `1888436520669979`.
- L2 withdrawal initiation was validated.
- Withdrawal tx observed: `0x388625362bfdae7e5d300e787a472d6b13a20ce752af9d9786dfd72f815e6254`.
- Withdrawal hash observed: `0x093313357595a541637e442d1c9e26b2a19a6d6da5c76d48bf3e28507a7f0812`.
- Withdrawal proof succeeded on L1.
- Proof tx observed: `0x707973bb5618d6b1b71129ea4bcee04243351c3ee8c3077206952ec1a2f71791`.
- Withdrawal finalization succeeded on L1.
- Finalize tx observed: `0xeacca9d2e70560e4ebe972a8f09849628a0b1f0b49045c74a2ecb135ba30772f`.
- Portal finalized flag verified as `true`.

## New Bridge App

Path:

```bash
/Users/piyushutkar/Desktop/veltrix-bridge
```

Run:

```bash
cd /Users/piyushutkar/Desktop/veltrix-bridge
PATH="/opt/homebrew/bin:$PATH" npm run dev
```

Verified:

```bash
PATH="/opt/homebrew/bin:$PATH" npm run build
PATH="/opt/homebrew/bin:$PATH" npm run lint
```

Current bridge app capabilities:

- Connect an EIP-1193 wallet such as MetaMask.
- Load Sepolia L1 balance.
- Load Veltrix L2 balance.
- Deposit ETH through `OptimismPortal.depositTransaction`.
- Initiate withdrawals through `L2ToL1MessagePasser.initiateWithdrawal`.
- Show recent submitted bridge actions.
- Show the withdrawal lifecycle: initiate, output proposed, prove, finalize.

## Monitoring

Start monitoring:

```bash
./ops/start-monitoring.sh
```

Health check:

```bash
./ops/health-check.sh
```

Grafana:

```text
http://localhost:3001
admin / veltrix
```

Prometheus:

```text
http://localhost:9090
```

## DigitalOcean VPS

SSH:

```bash
ssh -i ~/.ssh/veltrix_do_ed25519 root@159.223.145.63
```

Repo path:

```bash
/root/Veltrix
```

Service:

```bash
systemctl status veltrix-sepolia.service
journalctl -u veltrix-sepolia.service -f
```

Public RPC check:

```bash
curl -sS -X POST https://veltrix-rpc.404piyush.me \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
```

Expected:

```json
{"jsonrpc":"2.0","id":1,"result":"0xa455"}
```

Latest VPS catch-up observation:

```text
2026-05-05 IST: public RPC live, stack managed by systemd, containers running.
Fresh VPS sync is still catching up from genesis.
Observed: chain=42069 head=676 safe=0 finalized=0 l1_cursor_lag=12216.
```

## Important Commands

Check Sepolia health:

```bash
./ops/health-check.sh
```

Check proposer confirmations:

```bash
docker logs --since 30m veltrix-sepolia-op-proposer-1 2>&1 \
  | grep -E 'Proposing output root|Proposer tx successfully published|Transaction confirmed|rollup current L1 block still behind target|Failed to send proposal' \
  | tail -80
```

Run Sepolia bridge smoke test:

```bash
FINALIZE_WITHDRAWAL=1 bash ./ops/test-sepolia-bridge-flow.sh
```

Verify withdrawal finalization:

```bash
set -a; . ./.env; . ./ops/.env; set +a
cast call --rpc-url "$L1_RPC_URL" \
  0x9d6954E55297f9ae78e5c0dc2353c18b31aeA0b3 \
  'finalizedWithdrawals(bytes32)(bool)' \
  0x093313357595a541637e442d1c9e26b2a19a6d6da5c76d48bf3e28507a7f0812
```

## Remaining Work

- Add proof/finalize actions into the bridge UI instead of relying on scripts.
- Improve bridge UI design later; current version is functional, not final visual polish.
- Add environment-based production config for bridge/explorer URLs and RPC endpoints.
- Wait for the DigitalOcean Sepolia stack to catch up near L1 head before using it for public testing.
- Deploy explorer and bridge as separate apps/domains.
- Add faucet for testnet users.
- Add public developer docs for RPC, chain ID, bridge, faucet, and explorer.
- Add operational runbooks for backup, restart, key rotation, and funding.
- Run a longer public-testnet soak with proposer, batcher, monitoring, deposits, withdrawals, and finalizations.

## Supporting Docs

- `docs/public-testnet-checklist.md`
- `docs/screenshots/README.md`
- `docs/ops/runbook.md`
- `docs/deployment/contracts.md`
- `docs/bridge/limitations.md`
- `STATUS_2026-05-04.md`
- `docs/ops/aws-t3-small.md`
- `docs/ops/digitalocean.md`

## Phase 2: Ecosystem & Developer Tools
- 🏗️ **Chainlist Integration:** Metadata prepared for public submission.
- 🏗️ **Faucet Service:** Scaffolding complete; pending deployment to `faucet-veltrix.404piyush.me`.
