# RustDesk Quick Start Guide

Quick reference for deploying and using your RustDesk setup.

## System Overview

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│  xps17-nixos    │  LAN    │  optiplex-nixos  │  LAN    │ macmini-darwin  │
│  (Client)       │◄───────►│  (Server)        │◄───────►│ (Client/Host)   │
│                 │         │                  │         │                 │
│ • Optimized     │         │ • hbbs Server    │         │ • RustDesk      │
│   Client        │         │ • hbbr Relay     │         │   Client        │
│ • 60 FPS        │         │ • High Throughput│         │                 │
│ • Low Latency   │         │ • TCP BBR        │         │                 │
└─────────────────┘         └──────────────────┘         └─────────────────┘
        │                           │                             │
        └───────────────────────────┴─────────────────────────────┘
                    Tailscale VPN (Remote Access)
                          100.89.107.92
```

## Initial Setup (One-Time)

### 1. Deploy Server (optiplex-nixos)

```bash
cd /Users/morph/nix
./deploy-optiplex.sh
```

Or manually:
```bash
ssh -t optiplex-nixos "cd ~/nix && git pull && sudo nixos-rebuild switch --flake '.#' --impure"
```

### 2. Get Server Public Key

```bash
ssh optiplex-nixos "sudo cat /var/lib/rustdesk/id_ed25519.pub"
```

**Save this key!** You'll need it for all clients.

### 3. Deploy Client (xps17-nixos)

```bash
ssh -t xps17-nixos "cd ~/nix && git pull && sudo nixos-rebuild switch --flake '.#' --impure"
```

### 4. Configure Client

On xps17-nixos:
```bash
rustdesk-configure
```

Then in RustDesk app:
1. Settings → Network
2. ID Server: `optiplex-nixos.local`
3. Key: (paste the public key from step 2)
4. Click OK and restart RustDesk

## Daily Usage

### Connecting from xps17 to macmini

1. Open RustDesk on xps17-nixos
2. Enter macmini's RustDesk ID
3. Click "Connect"
4. Enter password

**Expected on LAN:**
- Latency: 1-10ms
- FPS: 60
- Quality: Best
- Connection: Direct

### Checking Connection Quality

During a session, look at the status bar:
- **Direct** = Best (P2P connection)
- **Relay** = Good (via optiplex server)
- **FPS** = Should be 60 on LAN
- **Latency** = Should be <10ms on LAN

## Network Scenarios

### On Home Network (LAN)
✅ **Best Performance**
- Server: `optiplex-nixos.local` (auto-discovered)
- Expected latency: 1-10ms
- Expected FPS: 60
- Quality: Best

### Remote (via Tailscale)
✅ **Secure Remote Access**
- Change server to: `100.89.107.92`
- Expected latency: 10-50ms
- FPS: 30-60 (adaptive)
- Quality: Adaptive

To switch:
```bash
# In RustDesk Settings → Network
# Change ID Server to: 100.89.107.92
```

## Troubleshooting

### Connection shows "Relay" instead of "Direct"

```bash
# Check if on same network
ping optiplex-nixos.local

# Check firewall allows UDP 21118
sudo nft list ruleset | grep 21118
```

### High latency on LAN

1. Check WiFi vs Ethernet (Ethernet is faster)
2. Check network usage: `iftop` or `bmon`
3. Reduce quality temporarily in RustDesk session settings
4. Verify both machines on same WiFi network (not guest network)

### Can't find optiplex-nixos.local

```bash
# Check Avahi is working
avahi-browse -a

# Try Tailscale IP instead
# RustDesk Settings → Network → ID Server: 100.89.107.92
```

### Poor video quality

1. Check hardware encoding is enabled (RustDesk settings)
2. Verify GPU drivers installed
3. Try different codec (h264 vs h265)
4. Check CPU usage (high = software encoding)

## Quick Commands

```bash
# Check server status
ssh optiplex-nixos "systemctl status rustdesk-hbbs rustdesk-hbbr"

# View server logs
ssh optiplex-nixos "journalctl -u rustdesk-hbbs -n 50 -f"

# Restart server
ssh optiplex-nixos "sudo systemctl restart rustdesk-hbbs rustdesk-hbbr"

# Get server public key
ssh optiplex-nixos "sudo cat /var/lib/rustdesk/id_ed25519.pub"

# Configure client on xps17
# (on xps17-nixos)
rustdesk-configure

# Check network optimizations
ssh xps17-nixos "sysctl net.ipv4.tcp_fastopen"
ssh optiplex-nixos "sysctl net.ipv4.tcp_congestion_control"
```

## Performance Targets

| Scenario | Latency | FPS | Bitrate | Connection |
|----------|---------|-----|---------|------------|
| LAN (same network) | 1-10ms | 60 | 10-50 Mbps | Direct |
| LAN (via server) | 5-15ms | 60 | 10-50 Mbps | Relay |
| Remote (Tailscale) | 10-50ms | 30-60 | 5-20 Mbps | Relay |
| Remote (Internet) | 50-200ms | 15-30 | 1-10 Mbps | Relay |

## Configuration Files

### Server (optiplex-nixos)
- Config: `/Users/morph/nix/hosts/optiplex-nixos/rustdesk.nix`
- Data: `/var/lib/rustdesk/` (on optiplex)
- Logs: `journalctl -u rustdesk-hbbs` / `-u rustdesk-hbbr`

### Client (xps17-nixos)
- Config: `/Users/morph/nix/hosts/xps17-nixos/rustdesk-client.nix`
- User Config: `~/.config/rustdesk/RustDesk2.toml` (on xps17)
- Setup Script: `rustdesk-configure`

## Port Reference

### Server (optiplex-nixos)
- TCP 21115 - ID/Rendezvous server
- UDP 21116 - ID/Rendezvous server
- TCP 21117 - Relay server
- TCP 21119 - Relay WebSocket
- TCP 21114 - Web console

### Client (xps17-nixos)
- TCP 21118 - Direct IP access
- UDP 21118 - Direct IP access

## Advanced Tips

### Maximum Performance (LAN)
1. Use Ethernet on both machines
2. Ensure hardware encoding enabled
3. Use "Best" quality setting
4. Close bandwidth-heavy apps
5. Use 5GHz WiFi (if wireless)

### Bandwidth-Constrained (Remote)
1. Use "Balanced" or "Low" quality
2. Reduce FPS to 30
3. Disable clipboard sync if not needed
4. Use h264 codec (more efficient)

### Security
- All connections require password
- Tailscale provides encryption for remote access
- Server only accessible via local network or Tailscale
- No public internet exposure

## Documentation

- **Full Server Setup**: `/Users/morph/nix/RUSTDESK-SETUP.md`
- **Full Client Setup**: `/Users/morph/nix/RUSTDESK-CLIENT-SETUP.md`
- **This Quick Start**: `/Users/morph/nix/RUSTDESK-QUICKSTART.md`

## Support Links

- RustDesk Official Docs: https://rustdesk.com/docs/
- Advanced Settings: https://rustdesk.com/docs/en/self-host/client-configuration/advanced-settings/
- Troubleshooting: https://rustdesk.com/docs/en/troubleshooting/
