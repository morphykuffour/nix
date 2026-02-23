#!/bin/bash

# Automated Stremio Addon Installation Script
# This script helps install Stremio addons by providing direct installation links

STREMIO_URL="https://optiplex-nixos.tailc585e.ts.net:8080"

echo "🎬 Stremio Addon Auto-Installation Helper"
echo "==========================================="
echo ""
echo "📍 Stremio Server: $STREMIO_URL"
echo ""

# Define addon configurations
declare -A ADDONS=(
    ["torrentio"]="https://torrentio.strem.fun/qualityfilter=720p,480p,cam,unknown|sizefilter=3GB/manifest.json"
    ["opensubtitles"]="https://opensubtitles.strem.fun/manifest.json"
    ["iptv-org"]="https://iptv-org.strem.fun/manifest.json"
    ["tmdb"]="https://tmdb-addon.strem.fun/manifest.json"
    ["anime-kitsu"]="https://anime-kitsu.strem.fun/manifest.json"
    ["watchhub"]="https://watchhub.strem.fun/manifest.json"
)

# Function to create installation links
create_install_links() {
    echo "🔗 Direct Installation Links:"
    echo "=============================="
    echo ""
    
    for addon in "${!ADDONS[@]}"; do
        url="${ADDONS[$addon]}"
        echo "📦 ${addon^} Addon:"
        echo "   Install URL: stremio://${url}"
        echo "   Web Install: ${url}"
        echo ""
    done
}

# Function to open Stremio and prepare for installation
open_stremio() {
    echo "🚀 Opening Stremio..."
    open "$STREMIO_URL"
    sleep 2
    
    echo ""
    echo "📋 Installation Steps:"
    echo "1. ✅ Stremio should now be open"
    echo "2. 🔐 Login to your Stremio account"
    echo "3. 🧩 Click 'Addons' in the sidebar (puzzle piece icon)"
    echo "4. ➕ Click '+ Add addon' button"
    echo "5. 📋 Copy/paste addon URLs from below"
    echo ""
}

# Function to install specific addon
install_addon() {
    local addon_name=$1
    local addon_url="${ADDONS[$addon_name]}"
    
    if [[ -z "$addon_url" ]]; then
        echo "❌ Unknown addon: $addon_name"
        echo "Available addons: ${!ADDONS[*]}"
        return 1
    fi
    
    echo "🎯 Installing $addon_name..."
    echo "📋 Copy this URL and paste it in Stremio:"
    echo ""
    echo "$addon_url"
    echo ""
    echo "Or click this link if you have a protocol handler:"
    echo "stremio://$addon_url"
    echo ""
    
    # Try to open with system handler
    if command -v open &> /dev/null; then
        echo "🚀 Attempting to open with system handler..."
        open "stremio://$addon_url" 2>/dev/null || echo "⚠️  Please copy URL manually"
    fi
}

# Function to create browser bookmarks
create_bookmarks() {
    local bookmark_file="/tmp/stremio_addons.html"
    
    cat > "$bookmark_file" << EOF
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Stremio Addons</TITLE>
<H1>Stremio Addons</H1>
<DL><p>
    <DT><H3>Stremio Addons - Install Links</H3>
    <DL><p>
EOF

    for addon in "${!ADDONS[@]}"; do
        url="${ADDONS[$addon]}"
        cat >> "$bookmark_file" << EOF
        <DT><A HREF="stremio://$url">${addon^} Addon</A>
EOF
    done
    
    cat >> "$bookmark_file" << EOF
    </DL><p>
</DL><p>
EOF
    
    echo "📑 Created bookmark file: $bookmark_file"
    echo "   Import this into your browser bookmarks"
    
    if command -v open &> /dev/null; then
        open "$bookmark_file"
    fi
}

# Main menu
case "${1:-menu}" in
    "menu"|"")
        echo "Choose an option:"
        echo ""
        echo "1) 🚀 Open Stremio and show installation guide"
        echo "2) 🔗 Show all addon installation links"
        echo "3) 🎯 Install specific addon"
        echo "4) 📑 Create browser bookmarks"
        echo "5) 🧪 Test addon connectivity"
        echo ""
        read -p "Enter your choice (1-5): " choice
        
        case $choice in
            1) open_stremio; create_install_links ;;
            2) create_install_links ;;
            3) 
                echo "Available addons: ${!ADDONS[*]}"
                read -p "Enter addon name: " addon
                install_addon "$addon"
                ;;
            4) create_bookmarks ;;
            5) 
                echo "🧪 Testing addon connectivity..."
                for addon in "${!ADDONS[@]}"; do
                    url="${ADDONS[$addon]}"
                    if curl -s --connect-timeout 5 "$url" | jq -e '.name' &>/dev/null; then
                        echo "✅ $addon: Working"
                    else
                        echo "⚠️  $addon: May be blocked or slow"
                    fi
                done
                ;;
            *) echo "Invalid choice" ;;
        esac
        ;;
    "open") open_stremio; create_install_links ;;
    "links") create_install_links ;;
    "bookmarks") create_bookmarks ;;
    "install") install_addon "$2" ;;
    *) 
        echo "Usage: $0 [open|links|bookmarks|install <addon>]"
        echo "Available addons: ${!ADDONS[*]}"
        ;;
esac

echo ""
echo "🎬 Happy Streaming! 🍿"