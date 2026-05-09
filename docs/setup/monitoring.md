# Monitoring Setup

Veltrix monitoring is local-only by default. It adds Prometheus and Grafana for the
local devnet and Sepolia-backed stacks without exposing anything publicly.

## Start

Start both stacks first:

```bash
./ops/start-veltrix.sh
./ops/start-sepolia-stack.sh
```

Then start monitoring:

```bash
./ops/start-monitoring.sh
```

Endpoints:

- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3001`
- Grafana login: `admin / veltrix`

## Health Check

For a quick terminal status:

```bash
./ops/health-check.sh
```

The script reports chain ID, execution head, unsafe head, safe head, finalized head,
and unsafe-to-safe lag for both local devnet and Sepolia-backed stacks.

## Metrics Sources

Prometheus scrapes:

- local `op-geth`, `op-node`, `op-batcher`, `op-proposer`
- Sepolia-backed `op-geth`, `op-node`, `op-batcher`, `op-proposer`

Metrics are enabled inside the Docker networks only. The OP service metrics ports are
not published to the host.
