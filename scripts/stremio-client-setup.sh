#!/usr/bin/env bash
# Stremio Client Setup Script
# Configures access to the Stremio server from any system on the Tailscale network

set -euo pipefail

# Get the optiplex-nixos Tailscale IP
OPTIPLEX_IP=$(tailscale status | grep "optiplex-nixos" | awk '{print $1}' || echo "")
CURRENT_HOST=$(hostname)

echo "🎬 Stremio Client Setup for $CURRENT_HOST"
echo "🔗 Connecting to Stremio server on optiplex-nixos"
echo ""

# Function to print colored output
print_step() {
    echo -e "\033[1;34m[STEP]\033[0m $1"
}

print_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# Check Tailscale connectivity
if [[ -z "$OPTIPLEX_IP" ]]; then
    print_error "Cannot find optiplex-nixos on Tailscale network"
    print_error "Please ensure:"
    print_error "  1. Tailscale is running on both systems"
    print_error "  2. Both systems are connected to the same tailnet"
    print_error "  3. optiplex-nixos is online"
    exit 1
fi

print_success "Found optiplex-nixos at $OPTIPLEX_IP"

# Test connectivity
print_step "Testing connectivity to Stremio server..."
if curl -s -o /dev/null -w "%{http_code}" "https://$OPTIPLEX_IP:12470" | grep -q "200\|302"; then
    print_success "Stremio server is accessible"
else
    print_warning "Stremio server may not be ready. Continuing with setup..."
fi

# Create desktop shortcuts and bookmarks
print_step "Creating access shortcuts..."

case "$(uname -s)" in
    Darwin*) # macOS
        # Create macOS app bundle for easy access
        APP_DIR="$HOME/Applications/Stremio Server.app"
        mkdir -p "$APP_DIR/Contents/MacOS"
        mkdir -p "$APP_DIR/Contents/Resources"
        
        cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>stremio-server</string>
    <key>CFBundleIdentifier</key>
    <string>com.stremio.server</string>
    <key>CFBundleName</key>
    <string>Stremio Server</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleIconFile</key>
    <string>stremio</string>
</dict>
</plist>
EOF

        cat > "$APP_DIR/Contents/MacOS/stremio-server" << EOF
#!/bin/bash
open "https://$OPTIPLEX_IP:12470"
EOF
        chmod +x "$APP_DIR/Contents/MacOS/stremio-server"
        print_success "macOS app created in Applications folder"
        ;;
        
    Linux*) # Linux
        # Create desktop file
        DESKTOP_FILE="$HOME/.local/share/applications/stremio-server.desktop"
        mkdir -p "$(dirname "$DESKTOP_FILE")"
        
        cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Name=Stremio Server
Comment=Access remote Stremio streaming server
Exec=firefox https://$OPTIPLEX_IP:12470
Icon=multimedia-video-player
Terminal=false
Type=Application
Categories=AudioVideo;Video;Network;
StartupNotify=true
EOF
        print_success "Desktop shortcut created"
        ;;
esac

# Create browser bookmarks file
BOOKMARKS_FILE="$HOME/stremio-bookmarks.html"
cat > "$BOOKMARKS_FILE" << EOF
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Stremio Server Bookmarks</TITLE>
<H1>Stremio Server Bookmarks</H1>
<DL><p>
    <DT><A HREF="https://$OPTIPLEX_IP:12470">🎬 Stremio Web Interface</A>
    <DT><A HREF="https://$OPTIPLEX_IP:8096">📺 Jellyfin Media Server</A>
    <DT><A HREF="https://$OPTIPLEX_IP:5055">🎞️ Jellyseerr (Request Movies/TV)</A>
    <DT><A HREF="https://$OPTIPLEX_IP:8701">🌊 qBittorrent</A>
    <DT><A HREF="https://$OPTIPLEX_IP:7878">🎬 Radarr (Movies)</A>
    <DT><A HREF="https://$OPTIPLEX_IP:8989">📺 Sonarr (TV Shows)</A>
    <DT><A HREF="https://$OPTIPLEX_IP:9696">🔍 Prowlarr (Indexers)</A>
</DL><p>
EOF

print_success "Browser bookmarks file created: $BOOKMARKS_FILE"

# Create command line aliases
ALIASES_FILE="$HOME/.stremio_aliases"
cat > "$ALIASES_FILE" << EOF
# Stremio Server Aliases
alias stremio="open 'https://$OPTIPLEX_IP:12470'"
alias jellyfin="open 'https://$OPTIPLEX_IP:8096'"
alias jellyseerr="open 'https://$OPTIPLEX_IP:5055'"
alias qbit="open 'https://$OPTIPLEX_IP:8701'"
alias radarr="open 'https://$OPTIPLEX_IP:7878'"
alias sonarr="open 'https://$OPTIPLEX_IP:8989'"
alias prowlarr="open 'https://$OPTIPLEX_IP:9696'"

# SSH into Stremio server
alias ssh-stremio="ssh optiplex-nixos"

# Stream a magnet link directly
stream-magnet() {
    if [[ -z "\$1" ]]; then
        echo "Usage: stream-magnet <magnet-link>"
        return 1
    fi
    open "https://$OPTIPLEX_IP:12470/?stream=\$1"
}
EOF

print_success "Command aliases created: $ALIASES_FILE"

echo ""
print_step "Installation Summary"
echo "────────────────────────────────────────"
echo "🌐 Stremio Server URL: https://$OPTIPLEX_IP:12470"
echo "🔐 Authentication: Automatic via Tailscale"
echo ""
echo "📱 Access Methods:"
case "$(uname -s)" in
    Darwin*) 
        echo "   • macOS App: ~/Applications/Stremio Server.app"
        ;;
    Linux*)
        echo "   • Desktop App: Search for 'Stremio Server' in applications"
        ;;
esac
echo "   • Browser Bookmarks: $BOOKMARKS_FILE"
echo "   • Command Line: Source $ALIASES_FILE and use 'stremio' command"
echo ""
echo "🎯 Media Management:"
echo "   • Request content: https://$OPTIPLEX_IP:5055 (Jellyseerr)"
echo "   • Browse library: https://$OPTIPLEX_IP:8096 (Jellyfin)"
echo "   • Manage downloads: https://$OPTIPLEX_IP:8701 (qBittorrent)"
echo ""

# Add aliases to shell profile
SHELL_PROFILE=""
case "$SHELL" in
    */zsh) SHELL_PROFILE="$HOME/.zshrc" ;;
    */bash) SHELL_PROFILE="$HOME/.bashrc" ;;
esac

if [[ -n "$SHELL_PROFILE" && -f "$SHELL_PROFILE" ]]; then
    if ! grep -q "source.*\.stremio_aliases" "$SHELL_PROFILE"; then
        echo "source $ALIASES_FILE" >> "$SHELL_PROFILE"
        print_success "Aliases added to $SHELL_PROFILE"
        echo "🔄 Run 'source $SHELL_PROFILE' or restart terminal to enable aliases"
    fi
fi

echo ""
print_step "Quick Start Guide"
echo "─────────────────"
echo "1. 🌐 Open Stremio: https://$OPTIPLEX_IP:12470"
echo "2. 🔐 Login with your Stremio account"
echo "3. 🔌 Add these recommended addons:"
echo "   • https://torrentio.strem.fun (Best torrent addon)"
echo "   • https://opensubtitles.strem.fun (Subtitles)"
echo "   • https://youtube.strem.fun (YouTube content)"
echo "4. 🎬 Start streaming!"
echo ""
print_success "Stremio client setup complete! 🎉"

# Test final connectivity
if curl -s -o /dev/null -w "%{http_code}" "https://$OPTIPLEX_IP:12470" | grep -q "200\|302"; then
    print_success "✅ Connection verified - you're ready to stream!"
else
    print_warning "⚠️  Connection test failed - server may still be starting up"
    echo "   Try again in a few minutes or check server status"
fi

echo ""
echo "🎬 Happy streaming from anywhere on your network! 🍿"