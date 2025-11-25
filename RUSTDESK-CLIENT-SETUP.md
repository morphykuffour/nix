# RustDesk Client Configuration for xps17-nixos

This document describes the optimized RustDesk client setup on xps17-nixos for low-latency LAN connections to optiplex-nixos (server) and macmini-darwin.

## Overview

The xps17-nixos has been configured as a high-performance RustDesk client optimized for:
- **Low-latency LAN connections** when on home network
- **Automatic server discovery** via mDNS/Avahi
- **Direct P2P connections** bypassing relay when possible
- **Hardware-accelerated encoding/decoding** for smooth 60 FPS
- **Tailscale fallback** for remote access

## What Has Been Configured

### 1. Network Optimizations
- **TCP Fast Open**: Enabled for lower connection latency
- **Low Latency Mode**: Reduces bufferbloat
- **Optimized TCP Keepalive**: Faster detection of dead connections
- **Direct Connection Port**: TCP/UDP 21118 opened in firewall

### 2. RustDesk Client Settings (Pre-configured)
The configuration automatically sets up optimal settings:

#### Network Performance
- ✅ **LAN Discovery**: Enabled - automatically find devices on local network
- ✅ **Direct IP Access**: Enabled - bypass relay server when on same LAN
- ✅ **UDP Hole Punching**: Enabled - establish P2P connections
- ✅ **Hardware Encoding**: Enabled - GPU acceleration for smooth video
- ✅ **Adaptive Bitrate**: Enabled - adjust quality based on network

#### Quality Settings (Optimized for LAN)
- **Image Quality**: Best (maximum quality for LAN)
- **Frame Rate**: 60 FPS (smooth experience)
- **Codec**: Auto (h264/h265 with hardware support)
- **Rendering**: Texture-based for smooth visuals

#### Server Configuration
- **Primary Server**: `optiplex-nixos.local` (LAN via mDNS)
- **Fallback Server**: `100.89.107.92` (Tailscale IP)
- **Direct Access Port**: 21118

### 3. Automatic Setup
- Systemd user service runs on first login
- Creates `~/.config/rustdesk/RustDesk2.toml` with optimal settings
- Manual configuration command: `rustdesk-configure`

## Deployment Instructions

### Step 1: Deploy the Configuration

Deploy to xps17-nixos:

```bash
# From your local machine
cd /Users/morph/nix
git add hosts/xps17-nixos/rustdesk-client.nix hosts/xps17-nixos/configuration.nix
git commit -m "Add optimized RustDesk client configuration for xps17-nixos"
git push

# SSH into xps17-nixos and rebuild
ssh -t xps17-nixos "cd ~/nix && git pull && sudo nixos-rebuild switch --flake '.#' --impure"
```

Or use the Makefile (if you have remote-switch set up):

```bash
cd /Users/morph/nix
make REMOTE_HOST=xps17-nixos REMOTE_USER=morph remote-switch
```

### Step 2: Get the RustDesk Server Public Key

You need the public key from optiplex-nixos server:

```bash
ssh optiplex-nixos "sudo cat /var/lib/rustdesk/id_ed25519.pub"
```

Copy this key - you'll need it in the next step.

### Step 3: Configure RustDesk Client

On xps17-nixos, the configuration is automatically set up on first login. To verify or manually configure:

```bash
# On xps17-nixos
rustdesk-configure
```

Then open RustDesk and:
1. Go to Settings (three dots) → Network
2. Verify the settings:
   - **ID Server**: Should show `optiplex-nixos.local`
   - **Relay Server**: Should be empty (uses ID server)
   - **API Server**: Should be empty
   - **Key**: Paste the public key from Step 2

3. Click "OK" and restart RustDesk

### Step 4: Verify Connection

Test the connection:

1. **From xps17-nixos → macmini-darwin**:
   - Open RustDesk on xps17-nixos
   - Enter the RustDesk ID of macmini-darwin
   - Connection should establish via optiplex server
   - Check connection type: Should show "Direct" or "Local" when on LAN

2. **Check Connection Quality**:
   - In an active session, click the stats icon
   - Look for:
     - **Connection Type**: "Direct" (best) or "Relay"
     - **FPS**: Should be 60
     - **Bitrate**: Should be high on LAN (10-50 Mbps)
     - **Latency**: Should be <10ms on LAN

## Network Scenarios

### Scenario 1: On Home LAN (Best Performance)

```
xps17-nixos → Local Network → optiplex-nixos (server) → macmini-darwin
```

- **Connection**: Direct P2P or via LAN server
- **Expected Latency**: 1-10ms
- **Expected Quality**: 60 FPS, best quality
- **Server Discovery**: Automatic via mDNS (`optiplex-nixos.local`)

### Scenario 2: Remote via Tailscale

```
xps17-nixos → Tailscale VPN → optiplex-nixos (server) → macmini-darwin
```

- **Connection**: Via Tailscale encrypted tunnel
- **Expected Latency**: 10-50ms (depends on internet)
- **Expected Quality**: 30-60 FPS, adaptive quality
- **Server**: Use Tailscale IP `100.89.107.92`

To use Tailscale server:
1. Open RustDesk Settings → Network
2. Change ID Server to `100.89.107.92`
3. Restart RustDesk

## Optimizations for Low Latency

### Already Configured
- ✅ Hardware encoding/decoding (GPU acceleration)
- ✅ Direct IP access (bypass relay)
- ✅ UDP enabled (faster than TCP)
- ✅ TCP Fast Open (faster handshake)
- ✅ LAN discovery (automatic device finding)
- ✅ 60 FPS enabled
- ✅ Best quality for LAN

### Additional Manual Optimizations

If you need even lower latency:

1. **Reduce Quality** (in RustDesk session):
   - During a session, click Settings
   - Image Quality → Balanced or Low
   - This trades quality for lower latency

2. **Direct Connection** (advanced):
   - If you know the local IP of macmini-darwin
   - You can connect directly: `192.168.x.x:21118`
   - Bypasses ID server entirely

3. **Wired Connection**:
   - Use Ethernet instead of WiFi for both machines
   - Can reduce latency from 5-10ms to 1-2ms

## Troubleshooting

### RustDesk Shows "Relay" Instead of "Direct"

**Cause**: Can't establish direct P2P connection

**Solutions**:
1. Check both machines are on same network
2. Verify firewall allows UDP 21118:
   ```bash
   sudo ufw status  # or check your firewall
   ```
3. Check if UPnP is enabled on router
4. Verify `optiplex-nixos.local` resolves:
   ```bash
   ping optiplex-nixos.local
   ```

### High Latency on LAN

**Cause**: Network congestion or WiFi interference

**Solutions**:
1. Check network stats in RustDesk session
2. Switch to 5GHz WiFi if on 2.4GHz
3. Use wired Ethernet connection
4. Reduce image quality temporarily
5. Check for other bandwidth-heavy applications

### Can't Connect to Server

**Cause**: Server not reachable or key mismatch

**Solutions**:
1. Verify optiplex server is running:
   ```bash
   ssh optiplex-nixos "systemctl status rustdesk-hbbs rustdesk-hbbr"
   ```
2. Check public key matches
3. Try Tailscale IP instead: `100.89.107.92`
4. Check firewall on optiplex:
   ```bash
   ssh optiplex-nixos "sudo nft list ruleset | grep 21115"
   ```

### Poor Video Quality or Low FPS

**Cause**: Hardware encoding not working or network issues

**Solutions**:
1. Verify GPU drivers installed on both machines
2. Check hardware encoding is enabled in RustDesk settings
3. Test with different codec (h264 vs h265)
4. Check CPU usage - high CPU may indicate software encoding
5. Verify network bandwidth with `iperf3`

## Performance Benchmarks

Expected performance on LAN:

| Metric | Expected Value | How to Check |
|--------|---------------|--------------|
| Latency | 1-10ms | RustDesk stats overlay |
| Frame Rate | 60 FPS | RustDesk stats overlay |
| Bitrate | 10-50 Mbps | RustDesk stats overlay |
| Connection Type | Direct/Local | RustDesk status bar |
| CPU Usage | <20% | `htop` or Task Manager |

## Configuration Files

### Auto-generated Configuration
- **Location**: `~/.config/rustdesk/RustDesk2.toml`
- **Created by**: `rustdesk-configure` or systemd service on first login
- **Editing**: Can be edited manually, but will be overwritten if deleted

### NixOS Configuration
- **Client Config**: `/Users/morph/nix/hosts/xps17-nixos/rustdesk-client.nix`
- **Main Config**: `/Users/morph/nix/hosts/xps17-nixos/configuration.nix`

## Advanced Configuration

### Using Different Servers Based on Network

You can create a script to automatically switch between LAN and Tailscale servers:

```bash
#!/usr/bin/env bash
# Switch RustDesk server based on network

if ping -c 1 optiplex-nixos.local &>/dev/null; then
    echo "On LAN - using local server"
    SERVER="optiplex-nixos.local"
else
    echo "Remote - using Tailscale"
    SERVER="100.89.107.92"
fi

# Update RustDesk config (requires restart)
sed -i "s/custom-rendezvous-server = .*/custom-rendezvous-server = \"$SERVER\"/" \
    ~/.config/rustdesk/RustDesk2.toml

echo "Server set to: $SERVER"
echo "Please restart RustDesk for changes to take effect"
```

Save this as `~/bin/rustdesk-switch-server.sh` and run when changing networks.

## Connecting to macmini-darwin

To connect from xps17-nixos to macmini-darwin:

### Prerequisites
1. macmini-darwin must have RustDesk installed
2. macmini-darwin must be configured to use same optiplex server
3. Both machines should be on same network for best performance

### Steps
1. Get macmini-darwin's RustDesk ID:
   - Open RustDesk on macmini
   - The ID is shown on the main screen
2. On xps17-nixos:
   - Open RustDesk
   - Enter the macmini ID
   - Click "Connect"
   - Enter password when prompted

### Expected Performance (LAN)
- Latency: 1-5ms
- Quality: 60 FPS, best quality
- Connection: Direct (P2P preferred)

## Files Modified

- `/Users/morph/nix/hosts/xps17-nixos/rustdesk-client.nix` (new)
- `/Users/morph/nix/hosts/xps17-nixos/configuration.nix` (modified)

## Next Steps

1. Deploy the configuration to xps17-nixos
2. Get the public key from optiplex-nixos server
3. Configure RustDesk client with the server key
4. Test connection to macmini-darwin
5. Verify low latency and smooth 60 FPS performance

## Related Documentation

- Server setup: `/Users/morph/nix/RUSTDESK-SETUP.md`
- Advanced settings: https://rustdesk.com/docs/en/self-host/client-configuration/advanced-settings/
