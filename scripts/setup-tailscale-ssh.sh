#!/usr/bin/env bash
# Setup Tailscale SSH across all systems

set -euo pipefail

echo "Tailscale SSH Setup for All Systems"
echo "======================================"
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

# Get current Tailscale status
print_step "Getting current Tailscale device status..."

TAILSCALE_DEVICES=$(tailscale status --json | jq -r '.Peer[] | select(.Online == true and (.HostName | contains("optiplex") or contains("xps17") or contains("macmini") or contains("raspberry"))) | "\(.HostName) \(.TailscaleIPs[0])"')

echo "Found these personal devices:"
echo "$TAILSCALE_DEVICES"
echo ""

# Test current SSH connectivity
print_step "Testing current SSH connectivity..."

test_ssh() {
    local hostname="$1"
    local ip="$2"
    local user="$3"
    
    print_info "Testing SSH to $hostname ($ip) as $user..."
    
    # Try regular SSH first
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$user@$ip" "hostname" >/dev/null 2>&1; then
        print_success "Regular SSH to $hostname works"
        return 0
    fi
    
    # Try Tailscale SSH
    if tailscale ssh "$hostname" "hostname" >/dev/null 2>&1; then
        print_success "Tailscale SSH to $hostname works"
        return 0
    fi
    
    print_warning "SSH to $hostname failed"
    return 1
}

# Test connectivity to known systems
echo ""
print_step "Testing SSH connectivity to all systems..."

WORKING_SSH=()
FAILED_SSH=()

# Test optiplex-nixos
if test_ssh "optiplex-nixos" "100.89.107.92" "morph"; then
    WORKING_SSH+=("optiplex-nixos")
else
    FAILED_SSH+=("optiplex-nixos")
fi

# Test xps17-nixos
if test_ssh "xps17-nixos" "100.104.224.46" "morph"; then
    WORKING_SSH+=("xps17-nixos")
else
    FAILED_SSH+=("xps17-nixos")
fi

# Test raspberrypi
if test_ssh "raspberrypi" "100.115.236.80" "user"; then
    WORKING_SSH+=("raspberrypi")
else
    FAILED_SSH+=("raspberrypi")
fi

echo ""
print_step "SSH Connectivity Summary"
echo "========================"
if [ ${#WORKING_SSH[@]} -gt 0 ]; then
    print_success "Working SSH connections:"
    for system in "${WORKING_SSH[@]}"; do
        echo "  $system"
    done
fi

if [ ${#FAILED_SSH[@]} -gt 0 ]; then
    print_warning "Failed SSH connections:"
    for system in "${FAILED_SSH[@]}"; do
        echo "  $system"
    done
fi

echo ""
print_step "Fixing SSH access for failed systems..."

# Function to fix SSH on a remote system
fix_remote_ssh() {
    local hostname="$1"
    local ip="$2"
    local user="$3"
    
    print_info "Attempting to fix SSH on $hostname..."
    
    # Check if we can access via any method
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$user@$ip" "echo 'Connected'" >/dev/null 2>&1; then
        print_info "Connected to $hostname, checking SSH service..."
        
        # Check if SSH service is running
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$user@$ip" "systemctl is-active ssh || systemctl is-active sshd || service ssh status" >/dev/null 2>&1; then
            print_success "SSH service is running on $hostname"
        else
            print_warning "SSH service not running on $hostname, attempting to start..."
            ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$user@$ip" "sudo systemctl start ssh || sudo systemctl start sshd || sudo service ssh start" >/dev/null 2>&1 || true
        fi
        
        # Enable SSH service
        ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$user@$ip" "sudo systemctl enable ssh || sudo systemctl enable sshd" >/dev/null 2>&1 || true
        
        return 0
    else
        print_warning "Cannot connect to $hostname to fix SSH"
        return 1
    fi
}

# Try to fix failed systems
for system in "${FAILED_SSH[@]}"; do
    case "$system" in
        "xps17-nixos")
            # xps17-nixos should work since it's NixOS with similar config
            print_info "xps17-nixos should have SSH enabled by default in NixOS config"
            ;;
        "raspberrypi") 
            fix_remote_ssh "raspberrypi" "100.115.236.80" "pi"
            fix_remote_ssh "raspberrypi" "100.115.236.80" "morph"
            ;;
    esac
done

echo ""
print_step "Creating SSH convenience commands..."

# Create SSH convenience script
SSH_SCRIPT="$HOME/.local/bin/ssh-tailscale"
mkdir -p "$(dirname "$SSH_SCRIPT")"

cat > "$SSH_SCRIPT" << 'EOF'
#!/usr/bin/env bash
# Tailscale SSH convenience wrapper

case "$1" in
    "optiplex"|"server")
        exec ssh morph@100.89.107.92 "${@:2}"
        ;;
    "xps17"|"laptop")
        exec ssh morph@100.104.224.46 "${@:2}"
        ;;
    "raspberry"|"pi")
        exec ssh pi@100.115.236.80 "${@:2}"
        ;;
    "list"|"ls")
        echo "Available systems:"
        echo "  optiplex, server   -> ssh morph@100.89.107.92"
        echo "  xps17, laptop      -> ssh morph@100.104.224.46" 
        echo "  raspberry, pi      -> ssh pi@100.115.236.80"
        ;;
    *)
        echo "Tailscale SSH Helper"
        echo "Usage: $0 {optiplex|xps17|raspberry|list} [command]"
        echo ""
        echo "Examples:"
        echo "  $0 optiplex                    # SSH to optiplex-nixos"
        echo "  $0 server 'systemctl status'  # Run command on server"
        echo "  $0 list                        # List available systems"
        ;;
esac
EOF

chmod +x "$SSH_SCRIPT"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    export PATH="$HOME/.local/bin:$PATH"
fi

print_success "SSH convenience script created at $SSH_SCRIPT"

echo ""
print_step "Testing fixed SSH connections..."

# Re-test all connections
echo ""
FINAL_WORKING=()
FINAL_FAILED=()

for system in optiplex-nixos xps17-nixos raspberrypi; do
    case "$system" in
        "optiplex-nixos")
            if test_ssh "$system" "100.89.107.92" "morph"; then
                FINAL_WORKING+=("$system")
            else
                FINAL_FAILED+=("$system")
            fi
            ;;
        "xps17-nixos")
            if test_ssh "$system" "100.104.224.46" "morph"; then
                FINAL_WORKING+=("$system")
            else
                FINAL_FAILED+=("$system")
            fi
            ;;
        "raspberrypi")
            if test_ssh "$system" "100.115.236.80" "user"; then
                FINAL_WORKING+=("$system")
            else
                FINAL_FAILED+=("$system")
            fi
            ;;
    esac
done

echo ""
print_step "Final SSH Status Report"
echo "======================"

if [ ${#FINAL_WORKING[@]} -gt 0 ]; then
    print_success "Working SSH systems (${#FINAL_WORKING[@]}/3):"
    for system in "${FINAL_WORKING[@]}"; do
        case "$system" in
            "optiplex-nixos") echo "  optiplex-nixos (server) - ssh morph@100.89.107.92" ;;
            "xps17-nixos")    echo "  xps17-nixos (laptop) - ssh morph@100.104.224.46" ;;
            "raspberrypi")    echo "  raspberrypi (pi) - ssh user@100.115.236.80" ;;
        esac
    done
fi

if [ ${#FINAL_FAILED[@]} -gt 0 ]; then
    echo ""
    print_warning "Systems still needing attention (${#FINAL_FAILED[@]}/3):"
    for system in "${FINAL_FAILED[@]}"; do
        case "$system" in
            "optiplex-nixos") echo "  optiplex-nixos - Check SSH service status" ;;
            "xps17-nixos")    echo "  xps17-nixos - May need NixOS rebuild or SSH service restart" ;;
            "raspberrypi")    echo "  raspberrypi - Enable SSH with 'sudo systemctl enable --now ssh'" ;;
        esac
    done
    
    echo ""
    print_info "Manual fixes needed:"
    echo ""
    echo "For Raspberry Pi:"
    echo "  1. Connect via physical access or VNC"
    echo "  2. Run: sudo systemctl enable --now ssh"
    echo "  3. Run: sudo ufw allow ssh (if using firewall)"
    echo ""
    echo "For xps17-nixos:"
    echo "  1. Check if system is actually running NixOS"
    echo "  2. Verify SSH service: systemctl status sshd"
    echo "  3. May need to rebuild NixOS config"
fi

echo ""
print_step "SSH Convenience Commands"
echo "========================"
echo "You can now use these convenient commands:"
echo ""
echo "  ssh-tailscale list           # List all systems"
echo "  ssh-tailscale optiplex       # SSH to server"
echo "  ssh-tailscale laptop         # SSH to xps17-nixos"
echo "  ssh-tailscale pi             # SSH to Raspberry Pi"
echo ""
echo "Or use the traditional method:"
echo "  ssh morph@100.89.107.92      # optiplex-nixos"
echo "  ssh morph@100.104.224.46     # xps17-nixos"
echo "  ssh user@100.115.236.80      # raspberrypi"

echo ""
if [ ${#FINAL_WORKING[@]} -eq 3 ]; then
    print_success "All SSH connections are working perfectly!"
elif [ ${#FINAL_WORKING[@]} -gt 0 ]; then
    print_success "${#FINAL_WORKING[@]} out of 3 systems have working SSH"
    print_warning "${#FINAL_FAILED[@]} systems need manual configuration"
else
    print_error "No SSH connections are working properly"
fi

echo ""
print_info "Pro tip: Add these aliases to your ~/.zshrc:"
echo ""
echo "alias sshopt='ssh morph@100.89.107.92'"
echo "alias sshlaptop='ssh morph@100.104.224.46'"
echo "alias sshpi='ssh user@100.115.236.80'"

exit 0
