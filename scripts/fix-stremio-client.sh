#!/bin/bash

# Fix Stremio client connection issues
# This script corrects common Stremio configuration problems

echo "Fixing Stremio Client Configuration..."

STREMIO_SERVER="https://optiplex-nixos.tailc585e.ts.net:8080"

echo ""
echo "Network Information:"
echo "  Stremio Server: $STREMIO_SERVER"
echo ""

# Test Stremio server
echo "Testing Stremio server..."
if curl -s --connect-timeout 5 "$STREMIO_SERVER" > /dev/null 2>&1; then
    echo "Stremio server is accessible"
else
    echo "Stremio server not responding - checking service..."
    ssh morph@100.89.107.92 "stremio-manager restart"
fi

echo ""
echo "Client Configuration Fix:"
echo ""
echo "1. In Stremio, go to Settings -> Streaming"
echo "2. DISABLE 'Override the streaming server URL'"
echo "3. Use the web interface directly at: $STREMIO_SERVER"
echo ""
echo "Direct Links:"
echo "  Stremio Web: $STREMIO_SERVER"
echo ""
echo "Quick Commands:"
echo "  tssh optiplex  - SSH to Stremio server"
echo ""
