#!/usr/bin/env bash
# Comprehensive Stremio Setup Script
# Configures Stremio with all available addons and optimal settings

set -euo pipefail

TAILSCALE_IP=$(tailscale ip -4)
HOSTNAME=$(hostname)

echo "🎬 Stremio Streaming Setup for $HOSTNAME"
echo "🔗 Tailscale IP: $TAILSCALE_IP"
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

# Check if running on optiplex-nixos
if [[ "$(hostname)" != "optiplex-nixos" ]]; then
    print_error "This script should be run on optiplex-nixos"
    exit 1
fi

print_step "Checking system status..."

# Check if Docker is running
if ! systemctl is-active --quiet docker; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Tailscale is running
if ! systemctl is-active --quiet tailscale; then
    print_error "Tailscale is not running. Please start Tailscale first."
    exit 1
fi

print_success "System checks passed"

print_step "Setting up Stremio directories..."

# Create necessary directories
sudo mkdir -p /var/lib/stremio/{web,streaming,cache,addons/{shared,torrentio-selfhosted,jackett-addon,local-addon}}
sudo chown -R morph:users /var/lib/stremio
chmod 750 /var/lib/stremio

print_success "Directories created"

print_step "Configuring addon API keys..."

# Create shared config directory for API keys
SHARED_CONFIG="/var/lib/stremio/addons/shared"

# Function to securely input API key
input_api_key() {
    local service="$1"
    local file="$2"
    local description="$3"
    
    if [[ ! -f "$SHARED_CONFIG/$file" ]]; then
        echo ""
        echo "🔑 Setting up $service"
        echo "$description"
        echo -n "Enter $service API key (or press Enter to skip): "
        read -s api_key
        echo
        
        if [[ -n "$api_key" ]]; then
            echo "$api_key" > "$SHARED_CONFIG/$file"
            chmod 600 "$SHARED_CONFIG/$file"
            print_success "$service API key saved"
        else
            print_warning "$service API key skipped"
        fi
    else
        print_success "$service API key already configured"
    fi
}

# Configure optional API keys for enhanced functionality
input_api_key "Real-Debrid" "real_debrid_key" \
    "Real-Debrid provides high-speed premium streaming from torrents"

input_api_key "OpenSubtitles" "opensubtitles_key" \
    "OpenSubtitles provides subtitles for movies and TV shows"

input_api_key "TMDB" "tmdb_api_key" \
    "The Movie Database provides metadata and artwork"

print_step "Starting Stremio services..."

# Rebuild NixOS configuration with Stremio
print_step "Rebuilding NixOS configuration..."
if sudo nixos-rebuild switch --flake /home/morph/nix#optiplex-nixos; then
    print_success "NixOS configuration rebuilt successfully"
else
    print_error "Failed to rebuild NixOS configuration"
    exit 1
fi

# Wait for services to start
print_step "Waiting for services to start..."
sleep 10

# Check service status
check_service() {
    local service="$1"
    local description="$2"
    
    if systemctl is-active --quiet "$service"; then
        print_success "$description is running"
        return 0
    else
        print_warning "$description is not running"
        return 1
    fi
}

echo ""
print_step "Checking service status..."
check_service "docker-stremio-web.service" "Stremio Web Interface"
check_service "docker-stremio-streaming-server.service" "Stremio Streaming Server"
check_service "tailscale-serve-config.service" "Tailscale Serve Configuration"

# Check if containers are running
print_step "Checking Docker containers..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(stremio|addon)" || true

echo ""
print_step "Configuration Summary"
echo "────────────────────────────────────────"
echo "🌐 Stremio Web Interface:"
echo "   Local:     http://localhost:12470"
echo "   Tailscale: https://$TAILSCALE_IP:12470"
echo ""
echo "🎥 Streaming Server:"
echo "   Local:     http://localhost:8080"
echo "   Tailscale: https://$TAILSCALE_IP:11470"
echo ""
echo "🔌 Available Addons:"
echo ""
echo "   PUBLIC ADDONS (configure in Stremio app):"
echo "   ├── Torrentio: https://torrentio.strem.fun"
echo "   ├── Jackett: https://jackett.elfhosted.com"
echo "   ├── OpenSubtitles: https://opensubtitles.strem.fun"
echo "   ├── YouTube: https://youtube.strem.fun"
echo "   ├── Anime Kitsu: https://anime-kitsu.strem.fun"
echo "   ├── TMDB: https://tmdb-addon.strem.fun"
echo "   └── IPTV Org: https://iptv-org.strem.fun"
echo ""
echo "   SELF-HOSTED ADDONS:"
echo "   ├── Torrentio: http://$TAILSCALE_IP:7000"
echo "   ├── Jackett: http://$TAILSCALE_IP:7001"
echo "   └── Local Files: http://$TAILSCALE_IP:7008"
echo ""
echo "🛠  Management Commands:"
echo "   ├── List addons: stremio-addon-manager list-addons"
echo "   ├── Setup Real-Debrid: stremio-addon-manager setup-debrid"
echo "   ├── Setup OpenSubtitles: stremio-addon-manager setup-opensubtitles"
echo "   └── Restart addon: stremio-addon-manager restart-addon <name>"
echo ""

print_step "Creating desktop shortcut..."
DESKTOP_FILE="$HOME/.local/share/applications/stremio-server.desktop"
mkdir -p "$(dirname "$DESKTOP_FILE")"

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Name=Stremio Server
Comment=Access Stremio streaming server
Exec=firefox https://$TAILSCALE_IP:12470
Icon=multimedia-video-player
Terminal=false
Type=Application
Categories=AudioVideo;Video;Network;
StartupNotify=true
EOF

print_success "Desktop shortcut created"

echo ""
print_step "Next Steps:"
echo "────────────"
echo "1. 🌐 Open Stremio Web: https://$TAILSCALE_IP:12470"
echo "2. 🔐 Create or login to your Stremio account"
echo "3. 🔌 Add public addons from the list above"
echo "4. ⚙️  Configure self-hosted addons if desired"
echo "5. 🎬 Start streaming!"
echo ""
echo "💡 Tips:"
echo "   • Use Torrentio addon for the best torrent streaming"
echo "   • Add Real-Debrid for premium high-speed streaming"
echo "   • OpenSubtitles addon provides subtitles"
echo "   • Your Jellyfin library is available through the Local addon"
echo ""
print_success "Stremio setup complete! 🎉"

# Final connectivity test
print_step "Testing connectivity..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:12470" | grep -q "200"; then
    print_success "Stremio Web Interface is accessible"
else
    print_warning "Stremio Web Interface may not be ready yet. Try again in a few minutes."
fi

echo ""
echo "🎬 Happy streaming! 🍿"