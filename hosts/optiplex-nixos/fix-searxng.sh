#!/usr/bin/env bash

# Fix SearXNG redirect loops and broken assets
# This script deploys the new SearXNG configuration with proper base_url

set -e

echo "🔧 Fixing SearXNG configuration..."
echo

# Step 1: Stop existing SearXNG containers
echo "📦 Step 1: Stopping existing SearXNG containers..."
ssh optiplex-nixos "docker stop searxng searxng-redis || true"
echo "✅ Containers stopped"
echo

# Step 2: Remove old containers (NixOS will recreate with new config)
echo "🗑️  Step 2: Removing old containers..."
ssh optiplex-nixos "docker rm searxng searxng-redis || true"
echo "✅ Containers removed"
echo

# Step 3: Apply NixOS configuration
echo "🚀 Step 3: Applying NixOS configuration..."
ssh optiplex-nixos "cd ~/nix && sudo nixos-rebuild switch --flake .#optiplex-nixos"
echo

# Step 4: Verify services
echo "✅ Step 4: Verifying services..."
echo
echo "SearXNG container status:"
ssh optiplex-nixos "docker ps | grep searxng"
echo
echo "Tailscale serve status:"
ssh optiplex-nixos "tailscale serve status | grep -A2 '/search'"
echo

echo "🎉 Done! SearXNG should now work correctly at:"
echo "   https://optiplex-nixos.tailc585e.ts.net/search"
echo
echo "Test it in your browser to verify:"
echo "  1. No redirect loops"
echo "  2. CSS/images load properly"
echo "  3. Search functionality works"
