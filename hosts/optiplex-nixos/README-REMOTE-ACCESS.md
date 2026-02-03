# optiplex-nixos Remote Access Guide

Complete guide for remotely accessing and controlling optiplex-nixos from macmini-darwin.

## System Overview

**optiplex-nixos** is configured with:
- **OS**: NixOS with Sway (Wayland compositor)
- **Display**: Headless (no physical monitor needed)
- **Network**: Tailscale VPN (100.89.107.92) + Local network
- **Auto-login**: Enabled for user `morph`

## Table of Contents

1. [VNC Remote Desktop](#vnc-remote-desktop)
2. [Input Leap Keyboard/Mouse Sharing](#input-leap-keyboardmouse-sharing)
3. [SSH Access](#ssh-access)
4. [Service Management](#service-management)
5. [Troubleshooting](#troubleshooting)

---

## VNC Remote Desktop

Access the optiplex-nixos desktop remotely using VNC.

### Quick Start

```bash
# Simple connection
vncviewer 100.89.107.92:5900

# Recommended connection with optimal settings
vncviewer -RemoteResize=1 -geometry 1920x1080 -QualityLevel=8 -CompressLevel=2 -AcceptClipboard=1 -SendClipboard=1 100.89.107.92:5900
```

### Using the Launch Script

The launch script provides automated VNC connection:

```bash
~/nix/hosts/optiplex-nixos/launch-waydroid-vnc.sh
```

**Features:**
- Auto-detects your display resolution
- Launches VNC viewer with optimal settings
- Attempts to start Waydroid (if needed)

### VNC Viewer Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `F8` | Open VNC menu (disconnect, fullscreen, etc.) |
| `Ctrl+Alt+Shift+F` | Toggle fullscreen |
| Close window | Disconnect from VNC |

### VNC Server Details

- **Protocol**: WayVNC (Wayland-native VNC server)
- **Port**: 5900
- **Authentication**: None (disabled for convenience)
- **Network**: Accessible via Tailscale and local network
- **Auto-start**: Yes (starts with Sway session)

---

## Input Leap Keyboard/Mouse Sharing

Share your Mac's keyboard and mouse with optiplex-nixos seamlessly.

### Server Configuration

**optiplex-nixos** runs Input Leap server:
- **Port**: 24800
- **Name**: `optiplex-nixos`
- **SSL**: Disabled (not needed on private network)
- **Layout**: optiplex (left) ↔ macmini (right)

### Client Setup on Mac

**Install Barrier** (Input Leap compatible):
```bash
brew install barrier
```

**Start the client:**
```bash
/Applications/Barrier.app/Contents/MacOS/barrierc -f --debug INFO --name macmini-darwin --disable-crypto 100.89.107.92:24800 &
```

**To stop the client:**
```bash
killall barrierc
```

### Screen Layout

```
┌─────────────────┐    ┌─────────────────┐
│  optiplex-nixos │    │ macmini-darwin  │
│     (LEFT)      │ ←→ │    (RIGHT)      │
└─────────────────┘    └─────────────────┘
```

### Using Input Leap

**Mouse Control:**
- Move mouse to **left edge** of Mac screen → appears on optiplex
- Move mouse to **right edge** of optiplex screen → appears on Mac

**Keyboard Shortcuts:**
- `Super+L` - Switch right (optiplex → Mac)
- `Super+H` - Switch left (Mac → optiplex)

**Features:**
- Keyboard input follows mouse position
- Clipboard sharing enabled
- Works seamlessly across screens

### Verify Connection

Check if client is connected:
```bash
# On Mac
ps aux | grep barrierc | grep -v grep

# On optiplex-nixos
ssh optiplex-nixos "sudo -u morph XDG_RUNTIME_DIR=/run/user/1000 journalctl --user -u deskflow-server -n 5"
```

Look for: `NOTE: client "macmini-darwin" has connected`

---

## SSH Access

### Basic Connection

```bash
ssh optiplex-nixos
# or
ssh morph@100.89.107.92
```

**Features:**
- Passwordless authentication (SSH keys)
- Passwordless sudo (for convenience)

### Common SSH Commands

```bash
# Check system status
ssh optiplex-nixos "uptime"

# Restart Sway
ssh optiplex-nixos "sudo systemctl restart greetd"

# View logs
ssh optiplex-nixos "journalctl -f"

# Rebuild NixOS configuration
ssh optiplex-nixos "cd ~/nix && git pull && sudo nixos-rebuild switch --flake .#optiplex-nixos"
```

---

## Service Management

### Service Status Commands

All these commands work from your Mac via SSH:

```bash
# VNC Server (WayVNC)
ssh optiplex-nixos "sudo -u morph XDG_RUNTIME_DIR=/run/user/1000 systemctl --user status wayvnc"

# Input Leap Server (Deskflow)
ssh optiplex-nixos "sudo -u morph XDG_RUNTIME_DIR=/run/user/1000 systemctl --user status deskflow-server"

# Sway (window manager)
ssh optiplex-nixos "pgrep -a sway"
```

### Service Control

```bash
# Restart VNC server
ssh optiplex-nixos "sudo -u morph bash -c 'export XDG_RUNTIME_DIR=/run/user/1000; systemctl --user restart wayvnc'"

# Restart Input Leap server
ssh optiplex-nixos "sudo -u morph bash -c 'export XDG_RUNTIME_DIR=/run/user/1000; systemctl --user restart deskflow-server'"

# View service logs
ssh optiplex-nixos "sudo -u morph XDG_RUNTIME_DIR=/run/user/1000 journalctl --user -u wayvnc -f"
ssh optiplex-nixos "sudo -u morph XDG_RUNTIME_DIR=/run/user/1000 journalctl --user -u deskflow-server -f"
```

### Helpful Aliases

These aliases are available when SSH'd into optiplex-nixos:

```bash
# VNC
wayvnc-status
wayvnc-restart
wayvnc-logs

# Input Leap
deskflow-status
deskflow-restart
deskflow-logs
```

---

## Troubleshooting

### VNC Issues

**Problem: Can't see the status bar at bottom of screen**

Solution: The VNC viewer window needs proper scaling
```bash
vncviewer -RemoteResize=1 -geometry 1920x1080 100.89.107.92:5900
```

**Problem: Red screen or no display**

Solutions:
```bash
# Wake the display
ssh optiplex-nixos "sudo -u morph bash -c 'export XDG_RUNTIME_DIR=/run/user/1000 SWAYSOCK=\$(find /run/user/1000 -name \"sway-ipc*\" | head -1); swaymsg \"output * dpms on\"'"

# Restart Sway
ssh optiplex-nixos "sudo systemctl restart greetd"
```

**Problem: VNC connection refused**

Check if WayVNC is running:
```bash
ssh optiplex-nixos "sudo -u morph XDG_RUNTIME_DIR=/run/user/1000 systemctl --user status wayvnc"
```

Restart if needed:
```bash
ssh optiplex-nixos "sudo -u morph XDG_RUNTIME_DIR=/run/user/1000 systemctl --user restart wayvnc"
```

### Input Leap Issues

**Problem: Client won't connect**

Check server is running:
```bash
ssh optiplex-nixos "sudo -u morph XDG_RUNTIME_DIR=/run/user/1000 systemctl --user status deskflow-server"
```

Check for SSL errors in logs:
```bash
ssh optiplex-nixos "sudo -u morph XDG_RUNTIME_DIR=/run/user/1000 journalctl --user -u deskflow-server -n 20"
```

Restart both server and client:
```bash
# Server
ssh optiplex-nixos "sudo -u morph XDG_RUNTIME_DIR=/run/user/1000 systemctl --user restart deskflow-server"

# Client (on Mac)
killall barrierc
/Applications/Barrier.app/Contents/MacOS/barrierc -f --debug INFO --name macmini-darwin --disable-crypto 100.89.107.92:24800 &
```

**Problem: Mouse/keyboard not working across screens**

1. Verify connection:
   ```bash
   ps aux | grep barrierc | grep -v grep
   ```

2. Check screen layout matches:
   - optiplex should be on LEFT
   - macmini should be on RIGHT

3. Try moving mouse to the correct edge (LEFT edge of Mac to go to optiplex)

### System Issues

**Problem: System won't boot or respond**

Physical access needed:
1. Connect monitor and keyboard to optiplex-nixos
2. Reboot the system
3. Check for boot errors

**Problem: Configuration changes not applying**

Force rebuild:
```bash
ssh optiplex-nixos "cd ~/nix && git pull && sudo nixos-rebuild switch --flake .#optiplex-nixos --show-trace"
```

**Problem: Can't SSH into optiplex-nixos**

Check Tailscale status:
```bash
tailscale status | grep optiplex
```

Try local network IP instead of Tailscale:
```bash
ssh morph@<local-ip>
```

---

## Network Information

### Tailscale
- **IP**: 100.89.107.92
- **Hostname**: optiplex-nixos.tailc585e.ts.net
- **Network**: Secure VPN mesh network

### Ports

| Service | Port | Protocol | Network |
|---------|------|----------|---------|
| SSH | 22 | TCP | Tailscale + Local |
| VNC (WayVNC) | 5900 | TCP | Tailscale |
| Input Leap | 24800 | TCP | Tailscale + Local |

### Firewall

Firewall rules are configured in NixOS to allow:
- SSH on all interfaces
- VNC on Tailscale interface
- Input Leap on Tailscale and local network (enp0s31f6)

---

## Quick Reference

### Daily Workflow

1. **Start VNC session:**
   ```bash
   vncviewer -RemoteResize=1 -geometry 1920x1080 100.89.107.92:5900
   ```

2. **Start Input Leap client:**
   ```bash
   /Applications/Barrier.app/Contents/MacOS/barrierc -f --debug INFO --name macmini-darwin --disable-crypto 100.89.107.92:24800 &
   ```

3. **Work seamlessly:**
   - Use VNC for full desktop access
   - Use Input Leap to control optiplex with your Mac keyboard/mouse
   - Move mouse across screen edges to switch control

4. **When finished:**
   - Close VNC viewer window
   - `killall barrierc` to stop Input Leap client

### Emergency Commands

```bash
# Reboot optiplex-nixos
ssh optiplex-nixos "sudo reboot"

# Check if system is responsive
ssh optiplex-nixos "uptime"

# View recent system logs
ssh optiplex-nixos "journalctl -b -n 100"

# Restart all user services
ssh optiplex-nixos "sudo systemctl restart greetd"
```

---

## Configuration Files

All configuration is managed through NixOS:

- **Main config**: `/home/morph/nix/hosts/optiplex-nixos/configuration.nix`
- **Sway config**: `/home/morph/nix/hosts/optiplex-nixos/sway.nix`
- **Input Leap**: `/home/morph/nix/hosts/optiplex-nixos/deskflow.nix`
- **Waydroid**: `/home/morph/nix/hosts/optiplex-nixos/waydroid.nix`

To modify configuration:
1. Edit files in git repo
2. Commit changes
3. Deploy: `ssh optiplex-nixos "cd ~/nix && git pull && sudo nixos-rebuild switch --flake .#optiplex-nixos"`

---

## Additional Resources

- **Sway Documentation**: https://swaywm.org/
- **WayVNC**: https://github.com/any1/wayvnc
- **Input Leap**: https://github.com/input-leap/input-leap
- **Barrier**: https://github.com/debauchee/barrier
- **NixOS Manual**: https://nixos.org/manual/nixos/stable/

---

*Last updated: 2026-02-03*
*System: optiplex-nixos running NixOS 24.05*
