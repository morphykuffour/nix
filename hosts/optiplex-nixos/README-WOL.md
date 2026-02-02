# Wake-on-LAN for optiplex-nixos

## MAC Address
- **Interface**: `enp0s31f6`
- **MAC Address**: `64:00:6a:91:1c:9a`

## Sending Wake-on-LAN Packets

### From macOS (macmini-darwin)
```bash
# Install wakeonlan if not already installed
brew install wakeonlan

# Wake the optiplex
wakeonlan 64:00:6a:91:1c:9a

# Or use local broadcast
wakeonlan -i 192.168.1.255 64:00:6a:91:1c:9a
```

### From Linux
```bash
# Install wakeonlan or etherwake
sudo apt install wakeonlan  # Debian/Ubuntu
sudo pacman -S wol          # Arch

# Wake the optiplex
wakeonlan 64:00:6a:91:1c:9a

# Or use etherwake
sudo etherwake 64:00:6a:91:1c:9a
```

### Via Tailscale
Wake-on-LAN requires being on the same local network. If you're remote:
1. SSH into another device on the same LAN as optiplex
2. Run the wakeonlan command from there

## Checking WoL Status on optiplex-nixos

```bash
# Check if WoL is enabled (should show 'g')
sudo ethtool enp0s31f6 | grep Wake-on

# Or use the alias (after rebuild)
wol-status

# Enable WoL manually if needed
sudo ethtool -s enp0s31f6 wol g
```

## Expected Output
When WoL is enabled, you should see:
```
Supports Wake-on: pumbg
Wake-on: g
```

The `g` means "Wake on MagicPacket" is enabled.

## BIOS/UEFI Settings
Make sure Wake-on-LAN is enabled in BIOS/UEFI:
1. Boot into BIOS/UEFI (usually F2, F12, or Del during startup)
2. Look for "Wake on LAN", "Power Management", or "Network Boot"
3. Enable "Wake on LAN" or "PME Event Wake Up"
4. Save and exit
