# DigitalOcean Deployment Notes

This is the current always-on Veltrix Sepolia host.

## Host

- Provider: DigitalOcean
- OS: Ubuntu 24.04.3 LTS
- Public IP: `159.223.145.63`
- RPC domain: `veltrix-rpc.404piyush.me`
- Repo path: `/root/Veltrix`
- Docker Compose project: `veltrix-sepolia`
- Systemd service: `veltrix-sepolia.service`
- Swap: `4 GB`
- Public RPC: `https://veltrix-rpc.404piyush.me`

## Access

```bash
ssh -i ~/.ssh/veltrix_do_ed25519 root@159.223.145.63
```

## Service Commands

```bash
systemctl status veltrix-sepolia.service
systemctl restart veltrix-sepolia.service
systemctl stop veltrix-sepolia.service
journalctl -u veltrix-sepolia.service -f
```

## Stack Checks

```bash
cd /root/Veltrix
./ops/health-check.sh
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

## Public RPC Check

```bash
curl -sS -X POST https://veltrix-rpc.404piyush.me \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
```

Expected:

```json
{"jsonrpc":"2.0","id":1,"result":"0xa455"}
```

## Nginx

Config:

```bash
/etc/nginx/sites-available/veltrix-rpc
```

Validate and reload:

```bash
nginx -t
systemctl reload nginx
```

Certificate:

```bash
certbot certificates
```

The first certificate was issued by Let's Encrypt on 2026-05-05 and expires on 2026-08-03. Certbot installed automatic renewal.

## Firewall And Ports

Firewall:

```bash
ufw status verbose
```

Expected public ingress:

- `22/tcp`
- `80/tcp`
- `443/tcp`

Raw Docker RPC ports should stay localhost-only:

```bash
ss -lntp | egrep ':(7546|8552|9546|80|443)'
```

Expected:

- `127.0.0.1:9546` for L2 execution RPC.
- `127.0.0.1:8552` for authenticated engine RPC.
- `127.0.0.1:7546` for rollup RPC.
- `0.0.0.0:80` and `0.0.0.0:443` for Nginx.

## Resource Protection

Docker log rotation is configured in:

```bash
/etc/docker/daemon.json
```

Expected:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  }
}
```

Check disk, memory, and swap:

```bash
df -h /
free -h
swapon --show
docker system df
```

## Current Caveat

The host starts from the rollup genesis state, so first Sepolia catch-up still takes time. Once caught up, it should stay near head because the VPS does not sleep like a laptop.

Latest observed initial VPS state:

```text
2026-05-05 IST
chain=42069 head=676 safe=0 finalized=0 l1_cursor_lag=12216
```
