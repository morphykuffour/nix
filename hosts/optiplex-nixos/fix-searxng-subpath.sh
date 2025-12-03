#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Fixing SearXNG /search subpath configuration..."
echo

# Step 1: Pull latest changes
echo "📥 Step 1: Pulling latest configuration..."
cd ~/nix
git pull
echo "✅ Configuration updated"
echo

# Step 2: Rebuild NixOS
echo "🔧 Step 2: Rebuilding NixOS configuration..."
sudo nixos-rebuild switch --flake .#optiplex-nixos
echo "✅ NixOS rebuild complete"
echo

# Step 3: Verify Tailscale routes
echo "✅ Step 3: Verifying Tailscale routes..."
echo
tailscale serve status
echo

# Step 4: Test endpoints
echo "🧪 Step 4: Testing endpoints..."
echo

echo "Testing /search subpath (should return HTML):"
curl -sL http://127.0.0.1:8888 | head -5
echo "..."
echo

echo "Testing :8443 port (should return HTML):"
curl -sL http://127.0.0.1:8888 | head -5
echo "..."
echo

echo "✅ Deployment complete!"
echo
echo "📝 Test in browser:"
echo "  - https://optiplex-nixos.tailc585e.ts.net/search"
echo "  - https://optiplex-nixos.tailc585e.ts.net:8443"
echo
echo "⚠️  IMPORTANT: If you get redirect loops when searching, read the troubleshooting guide:"
echo "    ~/nix/hosts/optiplex-nixos/SEARXNG-SUBPATH-FIX.md"
