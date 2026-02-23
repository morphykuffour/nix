#!/usr/bin/env bash
# Complete Stremio Deployment Script
# Deploys the entire Stremio streaming infrastructure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🚀 Complete Stremio Streaming Infrastructure Deployment"
echo "======================================================="
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

print_info() {
    echo -e "\033[1;35m[INFO]\033[0m $1"
}

# Check prerequisites
print_step "Checking prerequisites..."

if [[ ! -f "flake.nix" ]]; then
    print_error "Not in NixOS configuration directory. Please run from ~/nix/"
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    print_error "Git is required but not installed"
    exit 1
fi

print_success "Prerequisites check passed"

# Show current system
print_info "Current system: $(hostname)"
print_info "NixOS config: $(pwd)"

# Confirm deployment
echo ""
print_warning "This will deploy Stremio streaming infrastructure:"
echo "  • Complete Stremio server on optiplex-nixos"
echo "  • Integration with existing media stack"
echo "  • Tailscale network access configuration"
echo "  • Client setup tools for all systems"
echo ""

read -p "Continue with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Deployment cancelled"
    exit 0
fi

# Step 1: Verify configuration files
print_step "Verifying Stremio configuration files..."

required_files=(
    "hosts/optiplex-nixos/stremio.nix"
    "hosts/optiplex-nixos/configuration.nix"
    "scripts/stremio-setup.sh"
    "scripts/stremio-client-setup.sh"
    "scripts/test-stremio-setup.sh"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        print_success "Found $file"
    else
        print_error "Missing required file: $file"
        exit 1
    fi
done

# Step 2: Test NixOS configuration
print_step "Testing NixOS configuration syntax..."

if nix flake check --no-build 2>/dev/null; then
    print_success "Flake configuration is valid"
else
    print_warning "Flake check failed, continuing anyway..."
fi

# Step 3: Commit current configuration
print_step "Committing configuration changes..."

if git diff --quiet && git diff --cached --quiet; then
    print_info "No changes to commit"
else
    git add .
    if git commit -m "Deploy Stremio streaming infrastructure

- Add comprehensive Stremio server configuration
- Integrate with existing Tailscale network
- Include self-hosted and public addon support
- Add management and testing scripts
- Update firewall and service configurations"; then
        print_success "Configuration committed to git"
    else
        print_warning "Commit failed, continuing anyway..."
    fi
fi

# Step 4: Deploy to optiplex-nixos (if we're not already on it)
if [[ "$(hostname)" == "optiplex-nixos" ]]; then
    print_step "Building and switching to new configuration..."
    
    if sudo nixos-rebuild switch --flake ".#optiplex-nixos"; then
        print_success "NixOS configuration applied successfully"
    else
        print_error "NixOS rebuild failed"
        print_error "Check the error messages above and fix any issues"
        exit 1
    fi
else
    print_step "Deploying to optiplex-nixos remotely..."
    
    # Test SSH connectivity first
    if ! ssh -o ConnectTimeout=5 optiplex-nixos "echo 'SSH test successful'" 2>/dev/null; then
        print_error "Cannot connect to optiplex-nixos via SSH"
        print_error "Please ensure:"
        print_error "  1. optiplex-nixos is online and accessible"
        print_error "  2. SSH keys are set up correctly"
        print_error "  3. Tailscale is running on both systems"
        exit 1
    fi
    
    print_success "SSH connectivity verified"
    
    # Copy configuration and deploy
    if ssh optiplex-nixos "cd ~/nix && git pull && sudo nixos-rebuild switch --flake '.#optiplex-nixos'"; then
        print_success "Remote deployment successful"
    else
        print_error "Remote deployment failed"
        exit 1
    fi
fi

# Step 5: Wait for services to start
print_step "Waiting for services to initialize..."
sleep 15

# Step 6: Run server setup
print_step "Running server setup script..."

if [[ "$(hostname)" == "optiplex-nixos" ]]; then
    if "./scripts/stremio-setup.sh"; then
        print_success "Server setup completed"
    else
        print_warning "Server setup had issues, but continuing..."
    fi
else
    if ssh optiplex-nixos "cd ~/nix && ./scripts/stremio-setup.sh"; then
        print_success "Remote server setup completed"
    else
        print_warning "Remote server setup had issues, but continuing..."
    fi
fi

# Step 7: Run tests
print_step "Running deployment tests..."

if [[ "$(hostname)" == "optiplex-nixos" ]]; then
    TEST_RESULT=0
    "./scripts/test-stremio-setup.sh" || TEST_RESULT=$?
else
    TEST_RESULT=0
    ssh optiplex-nixos "cd ~/nix && ./scripts/test-stremio-setup.sh" || TEST_RESULT=$?
fi

if [[ $TEST_RESULT -eq 0 ]]; then
    print_success "All tests passed!"
else
    print_warning "Some tests failed (exit code: $TEST_RESULT)"
    print_warning "Check the test output above for details"
fi

# Step 8: Get connection information
print_step "Gathering connection information..."

if [[ "$(hostname)" == "optiplex-nixos" ]]; then
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "unknown")
    HOSTNAME="optiplex-nixos"
else
    TAILSCALE_IP=$(ssh optiplex-nixos "tailscale ip -4" 2>/dev/null || echo "unknown")
    HOSTNAME="optiplex-nixos"
fi

# Step 9: Deploy client configurations
echo ""
print_step "Setting up current system as client..."

if [[ "$(hostname)" != "optiplex-nixos" ]]; then
    if "./scripts/stremio-client-setup.sh"; then
        print_success "Client setup completed for $(hostname)"
    else
        print_warning "Client setup had issues"
    fi
fi

# Final summary
echo ""
echo "🎉 Stremio Deployment Complete!"
echo "================================"
echo ""
echo "🌐 Access Information:"
echo "   • Stremio Web:    https://$TAILSCALE_IP:12470"
echo "   • Jellyfin:       http://$TAILSCALE_IP:8096"
echo "   • Jellyseerr:     http://$TAILSCALE_IP:5055"
echo "   • qBittorrent:    http://$TAILSCALE_IP:8701"
echo ""
echo "🔧 Management:"
echo "   • Server setup:   ssh optiplex-nixos '~/nix/scripts/stremio-setup.sh'"
echo "   • Client setup:   ~/nix/scripts/stremio-client-setup.sh"
echo "   • Run tests:      ssh optiplex-nixos '~/nix/scripts/test-stremio-setup.sh'"
echo "   • Addon manager:  ssh optiplex-nixos 'stremio-addon-manager list-addons'"
echo ""
echo "📖 Documentation:"
echo "   • Full guide:     ~/nix/STREMIO_SETUP.md"
echo "   • Configuration:  ~/nix/hosts/optiplex-nixos/stremio.nix"
echo ""
echo "🚀 Quick Start:"
echo "   1. Open https://$TAILSCALE_IP:12470"
echo "   2. Login to your Stremio account"
echo "   3. Add recommended addons:"
echo "      • https://torrentio.strem.fun"
echo "      • https://opensubtitles.strem.fun"
echo "      • https://youtube.strem.fun"
echo "   4. Start streaming!"
echo ""

if [[ $TEST_RESULT -eq 0 ]]; then
    print_success "🎬 Your streaming infrastructure is ready! Happy streaming! 🍿"
else
    print_warning "⚠️  Deployment completed but some tests failed"
    print_info "The system should still work, but check the test output for any issues"
    print_info "Run tests again: ssh optiplex-nixos '~/nix/scripts/test-stremio-setup.sh'"
fi

echo ""
echo "💡 Next steps:"
echo "   • Configure Real-Debrid for premium streaming"
echo "   • Set up OpenSubtitles API key for subtitles"
echo "   • Explore available addons in the Stremio catalog"
echo "   • Request content through Jellyseerr"

exit $TEST_RESULT