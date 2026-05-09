# Screenshot Checklist

Use these screenshots for LinkedIn, status posts, or demo proof. Do not capture private keys, `.env` files, private RPC tokens, or wallet seed/private-key screens.

## Core Proof Screenshots

- Terminal output from:

```bash
./ops/health-check.sh
```

- Proposer confirmations:

```bash
docker logs --since 30m veltrix-sepolia-op-proposer-1 2>&1 \
  | grep -E 'Proposing output root|Proposer tx successfully published|Transaction confirmed' \
  | tail -40
```

- Batcher activity:

```bash
docker logs --since 30m veltrix-sepolia-op-batcher-1 2>&1 \
  | grep -E 'submitted|confirmed|batch|channel|tx' \
  | tail -80
```

- Running services:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

## Monitoring Screenshots

- Grafana dashboard: `http://localhost:3001`
- Prometheus targets: `http://localhost:9090/targets`
- Health check terminal next to Grafana is a strong combined screenshot.

Grafana login:

```text
admin / veltrix
```

## Explorer Screenshots

- Explorer home dashboard.
- Latest blocks panel.
- Latest transactions panel.
- One transaction detail page.
- One address detail page.

Explorer local path:

```bash
cd /Users/piyushutkar/Desktop/block-explorer/client
PATH="/opt/homebrew/bin:$PATH" npm run dev
```

## Bridge Screenshots

- Bridge home before wallet connection.
- Bridge after wallet connection.
- Sepolia and Veltrix L2 balances loaded.
- Deposit transaction submitted in the bridge activity list.
- Withdrawal initiated in the bridge activity list.
- Withdrawal lifecycle panel.

Bridge local path:

```bash
cd /Users/piyushutkar/Desktop/veltrix-bridge
PATH="/opt/homebrew/bin:$PATH" npm run dev
```

## On-Chain Evidence Screenshots

- Sepolia Etherscan page for deposit tx:

```text
0x0df568942fc840afe9e3a1df8bb917b67122191eb84e056225621e2c92217636
```

- L2 explorer page for withdrawal tx:

```text
0x388625362bfdae7e5d300e787a472d6b13a20ce752af9d9786dfd72f815e6254
```

- Sepolia Etherscan page for proof tx:

```text
0x707973bb5618d6b1b71129ea4bcee04243351c3ee8c3077206952ec1a2f71791
```

- Sepolia Etherscan page for finalize tx:

```text
0xeacca9d2e70560e4ebe972a8f09849628a0b1f0b49045c74a2ecb135ba30772f
```

## Do Not Screenshot

- `.env`
- Private keys
- Wallet seed phrases
- Paid RPC dashboard secrets
- Full machine file paths if you do not want local usernames visible
- Admin-only Grafana settings if deployed publicly
