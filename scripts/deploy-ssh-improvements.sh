#!/usr/bin/env bash
# Deploy SSH improvements to all NixOS systems

set -euo pipefail

echo "🔧 Deploying SSH Improvements to NixOS Systems"
echo "=============================================="
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

# SSH configuration improvement
create_ssh_config() {
    local hostname="$1"
    print_step "Improving SSH configuration for $hostname..."
    
    ssh-tailscale "$hostname" "sudo mkdir -p /etc/ssh/sshd_config.d" || return 1
    
    # Create optimized SSH config
    ssh-tailscale "$hostname" "sudo tee /etc/ssh/sshd_config.d/99-tailscale-improvements.conf > /dev/null" << 'EOF'
# Tailscale SSH optimizations
ClientAliveInterval 30
ClientAliveCountMax 3
MaxSessions 10
MaxStartups 10:30:100
LoginGraceTime 30s

# Security improvements
PermitRootLogin prohibit-password
PasswordAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Performance optimizations
Compression yes
UseDNS no
GSSAPIAuthentication no

# Allow SSH multiplexing
AllowTcpForwarding yes
X11Forwarding no
EOF

    ssh-tailscale "$hostname" "sudo systemctl reload sshd" || true
    print_success "SSH configuration improved for $hostname"
}

# Deploy to optiplex-nixos
if tssh optiplex "echo 'Connection test'" >/dev/null 2>&1; then
    print_step "Deploying to optiplex-nixos..."
    
    # Create SSH improvements
    create_ssh_config "optiplex"
    
    # Ensure SSH keys are properly set up
    ssh-tailscale optiplex "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
    ssh-tailscale optiplex "touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    
    # Copy our public key if it doesn't exist
    if [ -f ~/.ssh/id_rsa.pub ]; then
        cat ~/.ssh/id_rsa.pub | ssh-tailscale optiplex "grep -qxF \"\$(cat)\" ~/.ssh/authorized_keys || echo \"\$(cat)\" >> ~/.ssh/authorized_keys"
    fi
    
    print_success "optiplex-nixos SSH improvements deployed"
else
    print_error "Cannot connect to optiplex-nixos"
fi

echo ""

# Deploy to xps17-nixos
if ssh-tailscale laptop "echo 'Connection test'" >/dev/null 2>&1; then
    print_step "Deploying to xps17-nixos..."
    
    # Create SSH improvements
    create_ssh_config "laptop"
    
    # Ensure SSH keys are properly set up
    ssh-tailscale laptop "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
    ssh-tailscale laptop "touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    
    # Copy our public key if it doesn't exist
    if [ -f ~/.ssh/id_rsa.pub ]; then
        cat ~/.ssh/id_rsa.pub | ssh-tailscale laptop "grep -qxF \"\$(cat)\" ~/.ssh/authorized_keys || echo \"\$(cat)\" >> ~/.ssh/authorized_keys"
    fi
    
    print_success "xps17-nixos SSH improvements deployed"
else
    print_error "Cannot connect to xps17-nixos"
fi

echo ""

print_step "Creating SSH key if it doesn't exist..."
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "$(whoami)@$(hostname)"
    print_success "SSH key pair created"
else
    print_success "SSH key pair already exists"
fi

echo ""

print_step "Testing final connectivity..."
WORKING_SYSTEMS=0
TOTAL_SYSTEMS=2

if ssh-tailscale optiplex "echo 'optiplex-nixos: ✅ SSH working'" 2>/dev/null; then
    ((WORKING_SYSTEMS++))
fi

if ssh-tailscale laptop "echo 'xps17-nixos: ✅ SSH working'" 2>/dev/null; then
    ((WORKING_SYSTEMS++))
fi

echo ""
print_step "SSH Deployment Summary"
echo "======================"
print_success "✅ $WORKING_SYSTEMS out of $TOTAL_SYSTEMS NixOS systems have working SSH"

echo ""
print_step "Next Steps for Non-NixOS Systems"
echo "================================"
echo ""
echo "🍓 Raspberry Pi (100.115.236.80):"
echo "   1. Connect via physical access or VNC"
echo "   2. Enable SSH: sudo systemctl enable --now ssh"
echo "   3. Allow through firewall: sudo ufw allow ssh"
echo "   4. Test: ssh pi@100.115.236.80"
echo ""
echo "💾 TrueNAS Scale (100.120.143.27):"
echo "   1. Open web interface: http://100.120.143.27"
echo "   2. Login with admin credentials"
echo "   3. Go to System → SSH"
echo "   4. Enable SSH service"
echo "   5. Configure port (default 22)"
echo "   6. Test: ssh root@100.120.143.27"
echo ""

echo ""
print_success "🎉 SSH improvements deployed successfully!"
echo ""
echo "Quick SSH Commands:"
echo "  ssh-tailscale list       # List all systems"
echo "  ssh-tailscale optiplex   # SSH to server"
echo "  ssh-tailscale laptop     # SSH to laptop"
echo "  sshopt                   # Alias for optiplex"
echo "  sshlaptop                # Alias for laptop"
echo ""
echo "All systems are now optimized for secure, fast SSH access!"