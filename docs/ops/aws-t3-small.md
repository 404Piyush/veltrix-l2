# AWS t3.small Deployment Notes

This is the constrained AWS setup currently used for Veltrix Sepolia.

## Instance

- AMI: Amazon Linux 2023
- Instance type: `t3.small`
- Disk: `50 GB`
- Swap: `8 GB`
- Docker: managed by `systemd`
- Veltrix Sepolia stack: managed by `veltrix-sepolia.service`
- Host: `ec2-user@ec2-98-93-127-96.compute-1.amazonaws.com`

This is acceptable for a budget testnet host, but it is not ideal. Expect slower catch-up than a larger instance.

## Installed Service

Systemd unit:

```bash
/etc/systemd/system/veltrix-sepolia.service
```

Repo copy:

```bash
/home/ec2-user/Veltrix
```

Service commands:

```bash
sudo systemctl status veltrix-sepolia.service
sudo systemctl restart veltrix-sepolia.service
sudo systemctl stop veltrix-sepolia.service
```

Follow service boot logs:

```bash
sudo journalctl -u veltrix-sepolia.service -f
```

Container check:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

Health check:

```bash
cd /home/ec2-user/Veltrix
./ops/health-check.sh
```

Current first AWS catch-up observation:

```text
2026-05-05 IST: service enabled and running under systemd.
Containers had restart_count=0 after startup.
l1_cursor_lag moved from 9622 to 9558 during initial observation.
```

## Resource Protection

Docker log rotation is configured in:

```bash
/etc/docker/daemon.json
```

Expected settings:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  }
}
```

Swap:

```bash
free -h
swapon --show
```

Disk:

```bash
df -h /
docker system df
```

## Important Caveats

- First catch-up still takes time because the cloud host starts from the rollup genesis state.
- Once caught up, the VPS should stay near synced because it does not sleep like a laptop.
- `t3.small` can run out of CPU credits or memory under load.
- Keep Grafana/Prometheus optional on this size unless needed.
- Keep public RPC behind Nginx/HTTPS later; do not expose raw Docker ports unless intentionally testing.

## Local RPC Tunnel

Until `rpc.yourdomain.com` exists, use an SSH tunnel from the Mac:

```bash
ssh -i /Users/piyushutkar/Desktop/Veltrix/veltrix.pem \
  -L 9546:localhost:9546 \
  ec2-user@ec2-98-93-127-96.compute-1.amazonaws.com
```

The Sepolia Docker ports bind to localhost for safety. Point MetaMask or local scripts to:

```text
http://localhost:9546
```
