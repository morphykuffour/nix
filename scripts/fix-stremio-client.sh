#!/bin/bash

# Fix Stremio client connection issues
# This script corrects common Stremio configuration problems

echo "🔧 Fixing Stremio Client Configuration..."

# TrueNAS-Scale connection info
TRUENAS_IP="100.120.143.27"
STREMIO_SERVER="https://optiplex-nixos.tailc585e.ts.net:8080"

echo ""
echo "📡 Network Information:"
echo "  TrueNAS-Scale: $TRUENAS_IP"
echo "  Stremio Server: $STREMIO_SERVER"
echo ""

# Test TrueNAS connection
echo "🧪 Testing TrueNAS connection..."
if curl -s --connect-timeout 5 "http://$TRUENAS_IP" > /dev/null 2>&1; then
    echo "✅ TrueNAS-Scale is accessible"
else
    echo "⚠️  TrueNAS-Scale not responding (may need web interface enabled)"
fi

# Test Stremio server
echo "🧪 Testing Stremio server..."
if curl -s --connect-timeout 5 "$STREMIO_SERVER" > /dev/null 2>&1; then
    echo "✅ Stremio server is accessible"
else
    echo "❌ Stremio server not responding - checking service..."
    ssh morph@100.89.107.92 "stremio-manager restart"
fi

echo ""
echo "🎯 Client Configuration Fix:"
echo ""
echo "1. In Stremio, go to Settings → Streaming"
echo "2. DISABLE 'Override the streaming server URL'"
echo "3. Use the web interface directly at: $STREMIO_SERVER"
echo ""
echo "🔗 Direct Links:"
echo "  Stremio Web: $STREMIO_SERVER"
echo "  TrueNAS Web: http://$TRUENAS_IP (if web UI enabled)"
echo ""

# Create TrueNAS connection helper
echo "📝 Creating TrueNAS connection commands..."

# Add to shell aliases
if ! grep -q "alias truenas" ~/.zshrc 2>/dev/null; then
    echo "alias truenas='ssh root@$TRUENAS_IP'" >> ~/.zshrc
    echo "alias truenas-web='open http://$TRUENAS_IP'" >> ~/.zshrc
    echo "✅ Added TrueNAS aliases to ~/.zshrc"
fi

echo ""
echo "🚀 Quick Commands:"
echo "  truenas        - SSH to TrueNAS"
echo "  truenas-web    - Open TrueNAS web interface"
echo "  tssh optiplex  - SSH to Stremio server"
echo ""