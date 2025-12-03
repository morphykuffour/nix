#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Fixing SearXNG Redirect Loops"
echo "================================"
echo

echo "Problem: SearXNG is on /search subpath causing redirect loops"
echo "Solution: Move SearXNG to dedicated port :8443"
echo

# Step 1: Remove manual /search route
echo "✅ Step 1: Removing manual /search route..."
tailscale serve --https=443 --set-path=/search off || true
echo

# Step 2: Restart systemd service to reapply config
echo "✅ Step 2: Restarting tailscale-serve-config service..."
sudo systemctl restart tailscale-serve-config
echo

# Step 3: Update SearXNG container to remove base_url
echo "✅ Step 3: Updating SearXNG configuration..."
echo "Removing SEARXNG_BASE_URL environment variable (not needed on dedicated port)"

# Check current environment
echo
echo "Current SearXNG environment:"
docker inspect searxng --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -i base || echo "No BASE_URL set"

echo
echo "Note: To change environment variables, we need to recreate the container."
echo "This will be handled by NixOS rebuild. For now, SearXNG will work on :8443"
echo

# Step 4: Verify
echo "✅ Step 4: Verifying configuration..."
echo
echo "Tailscale serve status:"
tailscale serve status
echo

echo "✅ SearXNG should now be accessible at:"
echo "   https://optiplex-nixos.tailc585e.ts.net:8443"
echo
echo "🎯 Test this URL in your browser - it should work without redirect loops!"
echo
echo "Note: The old /search URL will no longer work (which is intended)."
echo "      Use :8443 port instead."
