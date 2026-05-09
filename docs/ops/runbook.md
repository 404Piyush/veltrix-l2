# Veltrix Operations Runbook

Operational commands for local and Sepolia-backed Veltrix work.

## Start Local Devnet

```bash
cd /Users/piyushutkar/Desktop/Veltrix
./ops/start-veltrix.sh
```

Reset local devnet only when you intentionally want a clean local state:

```bash
./ops/start-veltrix.sh --reset
```

## Start Sepolia Stack

```bash
cd /Users/piyushutkar/Desktop/Veltrix
./ops/start-sepolia-stack.sh
```

## DigitalOcean Sepolia Host

SSH:

```bash
ssh -i ~/.ssh/veltrix_do_ed25519 root@159.223.145.63
```

Repo:

```bash
cd /root/Veltrix
```

Systemd service:

```bash
systemctl status veltrix-sepolia.service
systemctl restart veltrix-sepolia.service
journalctl -u veltrix-sepolia.service -f
```

Health:

```bash
cd /root/Veltrix
./ops/health-check.sh
```

Public RPC:

```bash
curl -sS -X POST https://veltrix-rpc.404piyush.me \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
```

Expected chain ID result:

```json
{"jsonrpc":"2.0","id":1,"result":"0xa455"}
```

Security check:

```bash
ss -lntp | egrep ':(7546|8552|9546|80|443)'
ufw status verbose
```

Expected exposure:

- `80`, `443`, and `22` are public through UFW.
- `9546`, `8552`, and `7546` bind to `127.0.0.1` only.

## Start Monitoring

```bash
cd /Users/piyushutkar/Desktop/Veltrix
./ops/start-monitoring.sh
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

## Health Check

```bash
cd /Users/piyushutkar/Desktop/Veltrix
./ops/health-check.sh
```

Healthy Sepolia direction:

- `l1_cursor_lag` stays near the L1 head range, usually around `4-5` in the latest observed steady state.
- `safe_l2` advances.
- `finalized_l2` advances.
- `unsafe_safe_lag` may fluctuate while new unsafe blocks are produced and later derived safe.

## Logs

Proposer:

```bash
docker logs --since 30m veltrix-sepolia-op-proposer-1 2>&1 \
  | grep -E 'Proposing output root|Proposer tx successfully published|Transaction confirmed|rollup current L1 block still behind target|Failed to send proposal' \
  | tail -80
```

Batcher:

```bash
docker logs --since 30m veltrix-sepolia-op-batcher-1 2>&1 \
  | tail -120
```

Node:

```bash
docker logs --since 30m veltrix-sepolia-op-node-1 2>&1 \
  | tail -120
```

Execution client:

```bash
docker logs --since 30m veltrix-sepolia-op-geth-1 2>&1 \
  | tail -120
```

## Bridge Test

Run Sepolia bridge smoke test:

```bash
cd /Users/piyushutkar/Desktop/Veltrix
FINALIZE_WITHDRAWAL=1 bash ./ops/test-sepolia-bridge-flow.sh
```

If deposit waits too long, check whether the L1 safe cursor has crossed the deposit block:

```bash
./ops/health-check.sh
```

## Resume Withdrawal Finalization

```bash
cd /Users/piyushutkar/Desktop/Veltrix
L2_RPC=http://localhost:9546 WITHDRAWAL_CHECK_TIMEOUT=5m \
  bash ./ops/finalize-sepolia-withdrawal.sh \
  0x388625362bfdae7e5d300e787a472d6b13a20ce752af9d9786dfd72f815e6254
```

If it says the dispute game is still in progress, wait until the printed maturity time. That is an on-chain timing condition.

## Check Operator Balances

Set `L1_RPC` in the shell or source the environment first, then:

```bash
cast balance --ether --rpc-url "$L1_RPC" 0x6184AD388aa263135FA25D9ee48902159Aa7BF8d
cast balance --ether --rpc-url "$L1_RPC" 0x63748C342eabA529C428a1FEe2030FE5adbaDAB8
```

Addresses:

- Batcher: `0x6184AD388aa263135FA25D9ee48902159Aa7BF8d`
- Proposer: `0x63748C342eabA529C428a1FEe2030FE5adbaDAB8`

## Restart Services

Restart proposer:

```bash
docker restart veltrix-sepolia-op-proposer-1
```

Restart batcher:

```bash
docker restart veltrix-sepolia-op-batcher-1
```

Restart node:

```bash
docker restart veltrix-sepolia-op-node-1
```

Restart execution client:

```bash
docker restart veltrix-sepolia-op-geth-1
```

## Public Deployment Notes

- RPC is behind HTTPS at `https://veltrix-rpc.404piyush.me`.
- Use public read-only monitoring if you expose dashboards.
- Do not expose admin Grafana credentials.
- Do not expose private RPC tokens or operator private keys.
- Keep explorer and bridge as separate deployable apps.
