# Sway + WayVNC Remote Desktop Setup

## Overview

This configuration sets up Sway (i3 for Wayland) with WayVNC for remote desktop access over Tailscale.

### Components

- **Sway**: Wayland compositor (i3-compatible)
- **WayVNC**: VNC server for Wayland (replaces RustDesk)
- **greetd**: Display manager with autologin
- **Waydroid**: Android emulation (requires Wayland)

## First-Time Setup

After rebuilding, run this script to set up your Sway config:

```bash
bash /etc/nixos/sway-config-overlay.sh
```

This will:
- Copy your i3 config to `~/.config/sway/config`
- Apply Wayland compatibility fixes
- Add Sway-specific configuration

## Remote Access

### From macOS

1. Install a VNC client (NOT the built-in Screen Sharing):
   - **TigerVNC** (recommended): `brew install tiger-vnc`
   - **VNC Viewer**: Download from RealVNC website

2. Connect to your Tailscale IP:
   ```bash
   vncviewer 100.89.107.92:5900
   ```

### From Linux

```bash
vncviewer 100.89.107.92:5900
```

### From iOS/iPad

- Install "VNC Viewer" from the App Store
- Connect to: `100.89.107.92:5900`

## Configuration Differences from i3

### Removed (X11-only)
- `sxhkd` - Use Sway's built-in keybindings instead
- `picom` - Sway has built-in compositing
- `xbacklight` - Replaced with `brightnessctl`

### Wayland Replacements
- **Terminal**: `kitty` (Wayland-native)
- **Launcher**: `wofi` or `bemenu` (alternative to dmenu)
- **Brightness**: `brightnessctl` (instead of xbacklight)
- **Screenshots**: `grim` + `slurp` (instead of scrot)
- **Clipboard**: `wl-clipboard` (instead of xclip)

## Useful Commands

```bash
# Sway
swaymsg -t get_outputs          # List displays
swaymsg -t get_tree             # Window tree
swaymsg reload                  # Reload config

# WayVNC
systemctl --user status wayvnc  # Check status
systemctl --user restart wayvnc # Restart VNC server
systemctl --user stop wayvnc    # Stop VNC server

# Waydroid
waydroid show-full-ui           # Start Waydroid
waydroid session stop           # Stop Waydroid
```

## Session Selection at Login

With greetd, you can select different sessions:
- **Sway** (default with autologin)
- **i3** (X11, available as fallback)

To switch sessions, press Ctrl+C at greetd login to cancel autologin and select manually.

## Troubleshooting

### WayVNC won't start
```bash
# Check if Sway is running
echo $WAYLAND_DISPLAY

# Restart WayVNC
systemctl --user restart wayvnc

# Check logs
journalctl --user -u wayvnc -f
```

### Screen sharing not working
```bash
# Ensure portals are running
systemctl --user status xdg-desktop-portal
systemctl --user status xdg-desktop-portal-wlr
```

### Waydroid issues
```bash
# Initialize Waydroid (first time only)
sudo waydroid init

# Start container
sudo systemctl start waydroid-container
```

## References

- [WayVNC GitHub](https://github.com/any1/wayvnc)
- [Sway Documentation](https://github.com/swaywm/sway/wiki)
- [WayVNC + Tailscale Guide](https://acrogenesis.com/remote-access-to-omarchy-with-wayvnc-and-tailscale/)
