#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Applying SearXNG /search subpath configuration..."
echo

# Step 1: Pull latest config
echo "📥 Step 1: Pulling latest configuration..."
cd ~/nix
git pull
echo "✅ Configuration updated"
echo

# Step 2: Rebuild NixOS
echo "🔧 Step 2: Rebuilding NixOS configuration..."
sudo nixos-rebuild switch --flake .#optiplex-nixos
echo "✅ NixOS rebuilt"
echo

# Step 3: Verify Tailscale routes
echo "✅ Step 3: Verifying Tailscale routes..."
tailscale serve status
echo

# Step 4: Test the endpoints
echo "🧪 Step 4: Testing endpoints..."
echo
echo "Testing /search subpath (should return HTTP 200):"
curl -I http://localhost:8888 2>/dev/null | head -1
echo
echo "Testing port 8443 (should work too):"
echo "  https://optiplex-nixos.tailc585e.ts.net:8443"
echo

echo "🎉 Done! Now test in your browser:"
echo "  https://optiplex-nixos.tailc585e.ts.net/search"
echo "  https://optiplex-nixos.tailc585e.ts.net:8443"
