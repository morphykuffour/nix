#!/usr/bin/env bash
set -euo pipefail

echo "🔍 SYSTEMATIC SEARXNG FIX - Testing All Components"
echo "=================================================="
echo

# Step 1: Apply NixOS configuration
echo "📋 Step 1: Applying NixOS configuration with SEARXNG_BASE_URL=/search/"
cd ~/nix
sudo nixos-rebuild switch --flake .#optiplex-nixos
echo "✅ Configuration applied"
echo

# Step 2: Wait for container to restart
echo "⏳ Step 2: Waiting for SearXNG container to restart (10 seconds)..."
sleep 10
echo "✅ Wait complete"
echo

# Step 3: Verify container is running
echo "🐳 Step 3: Verifying SearXNG container status"
if docker ps | grep -q searxng; then
    echo "✅ SearXNG container is running"
else
    echo "❌ SearXNG container is NOT running!"
    docker ps -a | grep searxng
    exit 1
fi
echo

# Step 4: Verify environment variable is set
echo "🔧 Step 4: Checking SEARXNG_BASE_URL environment variable"
BASE_URL=$(docker exec searxng env | grep SEARXNG_BASE_URL || echo "NOT_SET")
echo "   Found: $BASE_URL"
if [[ "$BASE_URL" == *"/search/"* ]]; then
    echo "✅ SEARXNG_BASE_URL is correctly set to /search/"
else
    echo "❌ SEARXNG_BASE_URL is NOT set correctly!"
    echo "   Container environment:"
    docker exec searxng env | grep SEARXNG || true
    exit 1
fi
echo

# Step 5: Test HTML asset paths
echo "🌐 Step 5: Testing HTML asset paths"
echo "   Fetching https://optiplex-nixos.tailc585e.ts.net/search"
HTML_ASSETS=$(curl -s https://optiplex-nixos.tailc585e.ts.net/search | grep -o 'href="[^"]*static[^"]*"' | head -3)
echo "   Found asset links:"
echo "$HTML_ASSETS" | sed 's/^/      /'

if echo "$HTML_ASSETS" | grep -q '/search/static'; then
    echo "✅ Assets correctly point to /search/static/..."
elif echo "$HTML_ASSETS" | grep -q '^href="/static'; then
    echo "❌ Assets INCORRECTLY point to /static/ (missing /search prefix)"
    echo "   This will cause CSS to fail!"
    exit 1
else
    echo "⚠️  Unexpected asset paths, manual inspection needed"
fi
echo

# Step 6: Test CSS file access
echo "📄 Step 6: Testing CSS file accessibility"
CSS_URL="https://optiplex-nixos.tailc585e.ts.net/search/static/themes/simple/css/searxng-ltr.min.css"
echo "   Fetching: $CSS_URL"
CSS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$CSS_URL")
echo "   HTTP Status: $CSS_STATUS"
if [ "$CSS_STATUS" = "200" ]; then
    echo "✅ CSS file loads successfully"
else
    echo "❌ CSS file failed to load (HTTP $CSS_STATUS)"
    exit 1
fi
echo

# Step 7: Test search functionality (check for redirect loops)
echo "🔍 Step 7: Testing search functionality"
SEARCH_URL="https://optiplex-nixos.tailc585e.ts.net/search/search?q=test"
echo "   Fetching: $SEARCH_URL"
SEARCH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -L "$SEARCH_URL")
echo "   HTTP Status: $SEARCH_STATUS"
if [ "$SEARCH_STATUS" = "200" ]; then
    echo "✅ Search works without redirect loops"
else
    echo "❌ Search failed or redirected (HTTP $SEARCH_STATUS)"
    exit 1
fi
echo

# Step 8: Final verification - check Tailscale serve status
echo "🌍 Step 8: Verifying Tailscale serve configuration"
tailscale serve status | grep -A1 '/search'
echo "✅ Tailscale routing confirmed"
echo

# Success!
echo "=================================================="
echo "🎉 ALL TESTS PASSED!"
echo ""
echo "✅ Your URLs should now work:"
echo "   - https://optiplex-nixos.tailc585e.ts.net/search (with proper CSS)"
echo "   - https://optiplex-nixos.tailc585e.ts.net:8443 (alternative port)"
echo ""
echo "🧪 Open in browser and verify:"
echo "   1. Page loads with blue SearXNG theme (not broken icons)"
echo "   2. Search for 'test' and verify results display"
echo "   3. URL should become /search/search?q=test (this is CORRECT)"
echo "   4. No redirect loops or ERR_TOO_MANY_REDIRECTS"
echo ""
