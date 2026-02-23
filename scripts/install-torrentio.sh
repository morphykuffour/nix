#!/bin/bash

# Simple Torrentio Installation Helper
echo "🎬 Installing Torrentio Addon"
echo "=============================="
echo ""

STREMIO_URL="https://optiplex-nixos.tailc585e.ts.net:8080"
TORRENTIO_URL="https://torrentio.strem.fun/qualityfilter=720p,480p,cam,unknown|sizefilter=3GB/manifest.json"

echo "📍 Stremio Server: $STREMIO_URL"
echo "🔗 Torrentio URL: $TORRENTIO_URL"
echo ""

# Open Stremio
echo "🚀 Opening Stremio..."
open "$STREMIO_URL"
sleep 3

echo ""
echo "📋 MANUAL INSTALLATION STEPS:"
echo "1. ✅ Stremio should now be open"
echo "2. 🔐 Login to your Stremio account if not already"
echo "3. 🧩 Click 'Addons' in the left sidebar (puzzle piece icon)"
echo "4. ➕ Click the '+ Add addon' button (green button)"
echo "5. 📋 Copy and paste this URL into the text field:"
echo ""
echo "   $TORRENTIO_URL"
echo ""
echo "6. ✅ Click 'Install' button"
echo "7. 🎉 Torrentio should appear in your installed addons list"
echo ""

# Copy URL to clipboard if pbcopy is available
if command -v pbcopy &> /dev/null; then
    echo "$TORRENTIO_URL" | pbcopy
    echo "📋 URL copied to clipboard - just paste it in Stremio!"
    echo ""
fi

echo "🧪 TESTING:"
echo "After installation, test by:"
echo "1. Go to 'Search' in Stremio"
echo "2. Search for 'The Matrix'"
echo "3. Click on the movie"
echo "4. Look for Torrentio streams (720p/480p options under 3GB)"
echo ""

echo "🎬 Happy Streaming! 🍿"