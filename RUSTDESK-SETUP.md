# RustDesk Server Setup on optiplex-nixos

This document describes the complete RustDesk server setup with high throughput optimizations and Tailscale integration.

## What Has Been Configured

### 1. RustDesk Server Components
- **hbbs** (ID/Rendezvous Server): Handles client registration and connection brokering
  - TCP Port: 21115
  - UDP Port: 21116
  - Web Console: 21114
- **hbbr** (Relay Server): Handles data relay when direct P2P connection fails
  - TCP Port: 21117
  - WebSocket Port: 21119

### 2. High Throughput Optimizations
- **TCP BBR Congestion Control**: Modern congestion control algorithm for better throughput
- **Increased Network Buffers**: 128 MB max buffers for high-bandwidth connections
- **TCP Optimizations**:
  - TCP Fast Open enabled
  - MTU probing for optimal packet sizes
  - Disabled slow start after idle
  - TCP time-wait reuse enabled
- **Connection Limits**: Increased to handle many concurrent connections

### 3. Tailscale Integration
- RustDesk web console accessible via Tailscale Serve at `https://optiplex-nixos/rustdesk`
- All RustDesk ports accessible via Tailscale network
- When on home network: Can use local IP for better performance
- When away: Use Tailscale IP (100.89.107.92) for secure access

### 4. Security Features
- Dedicated `rustdesk` system user with minimal privileges
- Systemd hardening (NoNewPrivileges, PrivateTmp, ProtectSystem, ProtectHome)
- Firewall rules configured for both local and Tailscale access

## Deployment Instructions

### Step 1: Deploy the Configuration

Run the deployment script:

```bash
cd /Users/morph/nix
./deploy-optiplex.sh
```

This will:
1. SSH into optiplex-nixos
2. Pull the latest configuration from git
3. Build and activate the NixOS configuration
4. Show the status of RustDesk services
5. Display the public key for client configuration

Alternatively, deploy manually:

```bash
ssh -t optiplex-nixos
cd ~/nix
git pull
sudo nixos-rebuild switch --flake '.#' --impure
```

### Step 2: Retrieve the Public Key

After deployment, get the RustDesk public key:

```bash
ssh optiplex-nixos "sudo cat /var/lib/rustdesk/id_ed25519.pub"
```

Save this key - you'll need it for client configuration.

### Step 3: Verify Services

Check that both services are running:

```bash
ssh optiplex-nixos "systemctl status rustdesk-hbbs rustdesk-hbbr"
```

Both should show "active (running)" in green.

## Client Configuration

### On Your Home Network

Configure RustDesk clients with:
- **ID Server**: `<local-ip-of-optiplex>` or `optiplex-nixos.local`
- **Relay Server**: `<local-ip-of-optiplex>` or `optiplex-nixos.local`
- **API Server**: (leave empty)
- **Key**: `<paste the public key from Step 2>`

### When Away (via Tailscale)

Configure RustDesk clients with:
- **ID Server**: `100.89.107.92` or `optiplex-nixos.tail-scale.ts.net`
- **Relay Server**: `100.89.107.92` or `optiplex-nixos.tail-scale.ts.net`
- **API Server**: (leave empty)
- **Key**: `<paste the public key from Step 2>`

Note: Make sure Tailscale is running on both the client and server.

## Network Architecture

### Home Network Flow
```
Client (Home) → Local Network → optiplex-nixos (Direct, high performance)
```

### Remote Access Flow
```
Client (Remote) → Tailscale VPN → optiplex-nixos (Encrypted, via Tailscale)
```

### Why This Setup is Optimal

1. **High Throughput**: TCP BBR and optimized buffers ensure maximum performance
2. **Flexibility**: Works both on local network and remotely via Tailscale
3. **Security**: Tailscale provides encrypted access without exposing ports to internet
4. **Simplicity**: Same server, just different IP depending on location

## Firewall Ports

The following ports are open on optiplex-nixos:

### TCP Ports
- 21115 - hbbs ID/Rendezvous server
- 21117 - hbbr Relay server
- 21119 - hbbr WebSocket
- 21114 - hbbs Web console (mainly for Tailscale)

### UDP Ports
- 21116 - hbbs ID/Rendezvous server

All these ports are accessible on:
- Local network interface
- Tailscale interface (tailscale0)

## Monitoring and Troubleshooting

### Check Service Status
```bash
ssh optiplex-nixos "systemctl status rustdesk-hbbs rustdesk-hbbr"
```

### View Logs
```bash
# hbbs logs
ssh optiplex-nixos "journalctl -u rustdesk-hbbs -n 50 -f"

# hbbr logs
ssh optiplex-nixos "journalctl -u rustdesk-hbbr -n 50 -f"
```

### Check Network Optimizations
```bash
ssh optiplex-nixos "sysctl net.ipv4.tcp_congestion_control"
# Should output: net.ipv4.tcp_congestion_control = bbr

ssh optiplex-nixos "sysctl net.core.rmem_max"
# Should output: net.core.rmem_max = 134217728
```

### Restart Services
```bash
ssh optiplex-nixos "sudo systemctl restart rustdesk-hbbs rustdesk-hbbr"
```

## Web Console Access

The RustDesk web console is available at:
- Via Tailscale: `https://optiplex-nixos/rustdesk`
- Direct: `http://100.89.107.92:21114` (when on Tailscale)

Note: The web console provides admin functionality for managing connected clients.

## Performance Tips

1. **On Home Network**: Use local IP for lowest latency and highest throughput
2. **Remote Access**: Ensure Tailscale is using direct connection (check with `tailscale status`)
3. **Quality Settings**: In RustDesk client, you can adjust quality settings based on bandwidth
4. **Direct P2P**: When possible, RustDesk will establish direct P2P connections for best performance

## Files Modified

- `/Users/morph/nix/hosts/optiplex-nixos/rustdesk.nix` (new)
- `/Users/morph/nix/hosts/optiplex-nixos/configuration.nix` (modified to import rustdesk.nix)
- `/Users/morph/nix/deploy-optiplex.sh` (new deployment script)

## Next Steps

1. Run the deployment script: `./deploy-optiplex.sh`
2. Get the public key and configure your RustDesk clients
3. Test connection from both home network and remote (via Tailscale)
4. Enjoy high-performance remote desktop access!
