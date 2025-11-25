#!/usr/bin/env bash
# Deploy configuration to optiplex-nixos

set -e

echo "Deploying RustDesk configuration to optiplex-nixos..."

# SSH into the server and run the deployment
ssh -t optiplex-nixos << 'EOF'
cd ~/nix
git pull
sudo nixos-rebuild switch --flake '.#' --impure
EOF

echo ""
echo "Deployment complete! Checking RustDesk services..."

# Check service status
ssh optiplex-nixos << 'EOF'
echo "=== RustDesk Services Status ==="
systemctl status rustdesk-hbbs --no-pager | head -15
echo ""
systemctl status rustdesk-hbbr --no-pager | head -15
echo ""
echo "=== RustDesk Public Key ==="
sudo cat /var/lib/rustdesk/id_ed25519.pub
EOF

echo ""
echo "Setup complete! Your Tailscale IP is: 100.89.107.92"
echo "Configure your RustDesk clients with:"
echo "  ID Server: 100.89.107.92 (or optiplex-nixos.tail-scale.ts.net)"
echo "  Relay Server: 100.89.107.92"
echo "  Key: (see above)"
