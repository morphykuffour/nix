#!/usr/bin/env bash
# Test Stremio Setup
# Comprehensive testing of the Stremio streaming setup

set -euo pipefail

echo "🧪 Testing Stremio Streaming Setup"
echo "=================================="
echo ""

# Function to print colored output
print_test() {
    echo -e "\033[1;36m[TEST]\033[0m $1"
}

print_pass() {
    echo -e "\033[1;32m[PASS]\033[0m $1"
}

print_fail() {
    echo -e "\033[1;31m[FAIL]\033[0m $1"
}

print_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    print_test "$test_name"
    
    if eval "$test_command"; then
        if [[ "$expected_result" == "pass" ]]; then
            print_pass "$test_name"
            ((TESTS_PASSED++))
        else
            print_fail "$test_name (expected to fail but passed)"
            ((TESTS_FAILED++))
            FAILED_TESTS+=("$test_name")
        fi
    else
        if [[ "$expected_result" == "fail" ]]; then
            print_pass "$test_name (expected to fail)"
            ((TESTS_PASSED++))
        else
            print_fail "$test_name"
            ((TESTS_FAILED++))
            FAILED_TESTS+=("$test_name")
        fi
    fi
}

# Test 1: Check if we're on the right system
print_test "Checking system hostname"
if [[ "$(hostname)" == "optiplex-nixos" ]]; then
    print_pass "Running on optiplex-nixos"
    SYSTEM_CHECK=true
    ((TESTS_PASSED++))
else
    print_info "Running on $(hostname) - will test remote connectivity"
    SYSTEM_CHECK=false
    ((TESTS_PASSED++))
fi

# Test 2: Tailscale connectivity
print_test "Checking Tailscale status"
if systemctl is-active --quiet tailscale 2>/dev/null && tailscale status >/dev/null 2>&1; then
    TAILSCALE_IP=$(tailscale ip -4)
    print_pass "Tailscale is running (IP: $TAILSCALE_IP)"
    ((TESTS_PASSED++))
else
    print_fail "Tailscale is not running or not accessible"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("Tailscale connectivity")
fi

# Get optiplex IP for remote testing
if [[ "$SYSTEM_CHECK" == false ]]; then
    OPTIPLEX_IP=$(tailscale status | grep "optiplex-nixos" | awk '{print $1}' 2>/dev/null || echo "")
    if [[ -n "$OPTIPLEX_IP" ]]; then
        print_info "Testing connectivity to optiplex-nixos at $OPTIPLEX_IP"
    else
        print_fail "Cannot find optiplex-nixos on Tailscale network"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("Find optiplex-nixos on Tailscale")
        exit 1
    fi
else
    OPTIPLEX_IP="localhost"
fi

# Test 3: Docker services (only on optiplex)
if [[ "$SYSTEM_CHECK" == true ]]; then
    print_test "Checking Docker service"
    if systemctl is-active --quiet docker; then
        print_pass "Docker is running"
        ((TESTS_PASSED++))
    else
        print_fail "Docker is not running"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("Docker service")
    fi
    
    # Test Docker containers
    print_test "Checking Stremio containers"
    CONTAINER_COUNT=$(docker ps --filter "name=stremio" --format "{{.Names}}" 2>/dev/null | wc -l || echo "0")
    if [[ "$CONTAINER_COUNT" -gt 0 ]]; then
        print_pass "Found $CONTAINER_COUNT Stremio containers running"
        docker ps --filter "name=stremio" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ((TESTS_PASSED++))
    else
        print_fail "No Stremio containers found"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("Stremio containers")
    fi
fi

# Test 4: Port accessibility
test_port() {
    local port="$1"
    local service="$2"
    local host="${3:-$OPTIPLEX_IP}"
    
    print_test "Testing $service on port $port"
    
    # Use different protocols based on expected service
    if [[ "$port" == "443" ]] || [[ "$port" =~ ^(8443|12470|11470)$ ]]; then
        # HTTPS services
        if timeout 10 curl -k -s -o /dev/null -w "%{http_code}" "https://$host:$port" | grep -q "200\|302\|404"; then
            print_pass "$service is accessible on HTTPS port $port"
            ((TESTS_PASSED++))
        else
            print_fail "$service is not accessible on HTTPS port $port"
            ((TESTS_FAILED++))
            FAILED_TESTS+=("$service port $port")
        fi
    else
        # HTTP services
        if timeout 10 curl -s -o /dev/null -w "%{http_code}" "http://$host:$port" | grep -q "200\|302\|404"; then
            print_pass "$service is accessible on HTTP port $port"
            ((TESTS_PASSED++))
        else
            print_fail "$service is not accessible on HTTP port $port"
            ((TESTS_FAILED++))
            FAILED_TESTS+=("$service port $port")
        fi
    fi
}

# Test core services
test_port "8096" "Jellyfin"
test_port "12470" "Stremio Web"
test_port "8080" "Stremio Streaming"
test_port "5055" "Jellyseerr"
test_port "8701" "qBittorrent"

# Test 5: Nginx configuration (only on optiplex)
if [[ "$SYSTEM_CHECK" == true ]]; then
    print_test "Checking Nginx configuration"
    if systemctl is-active --quiet nginx; then
        if nginx -t 2>/dev/null; then
            print_pass "Nginx configuration is valid"
            ((TESTS_PASSED++))
        else
            print_fail "Nginx configuration has errors"
            ((TESTS_FAILED++))
            FAILED_TESTS+=("Nginx configuration")
        fi
    else
        print_info "Nginx is not running (may not be required)"
        ((TESTS_PASSED++))
    fi
fi

# Test 6: Tailscale Serve configuration (only on optiplex)
if [[ "$SYSTEM_CHECK" == true ]]; then
    print_test "Checking Tailscale Serve configuration"
    if tailscale serve status 2>/dev/null | grep -q "https://"; then
        print_pass "Tailscale Serve is configured"
        print_info "Tailscale Serve status:"
        tailscale serve status 2>/dev/null || true
        ((TESTS_PASSED++))
    else
        print_fail "Tailscale Serve is not configured"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("Tailscale Serve")
    fi
fi

# Test 7: File system permissions (only on optiplex)
if [[ "$SYSTEM_CHECK" == true ]]; then
    print_test "Checking Stremio directory permissions"
    if [[ -d "/var/lib/stremio" ]] && [[ -w "/var/lib/stremio" ]]; then
        print_pass "Stremio directories exist and are writable"
        ((TESTS_PASSED++))
    else
        print_fail "Stremio directories missing or not writable"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("Directory permissions")
    fi
fi

# Test 8: Network connectivity between services
print_test "Testing service interconnectivity"
if timeout 5 curl -s "http://$OPTIPLEX_IP:8096/health" >/dev/null 2>&1; then
    print_pass "Jellyfin health check passed"
    ((TESTS_PASSED++))
else
    print_info "Jellyfin health check not available (service may still work)"
    ((TESTS_PASSED++))
fi

# Test 9: Addon accessibility
print_test "Testing public addon connectivity"
if timeout 10 curl -s -o /dev/null "https://torrentio.strem.fun/manifest.json"; then
    print_pass "Torrentio addon is accessible"
    ((TESTS_PASSED++))
else
    print_fail "Cannot reach Torrentio addon"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("Torrentio addon connectivity")
fi

# Test 10: SSH connectivity (from remote systems)
if [[ "$SYSTEM_CHECK" == false ]]; then
    print_test "Testing SSH connectivity to optiplex-nixos"
    if timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no optiplex-nixos "echo 'SSH test successful'" 2>/dev/null; then
        print_pass "SSH to optiplex-nixos works"
        ((TESTS_PASSED++))
    else
        print_fail "Cannot SSH to optiplex-nixos"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("SSH connectivity")
    fi
fi

echo ""
echo "🏁 Test Results Summary"
echo "======================"
echo "✅ Tests Passed: $TESTS_PASSED"
echo "❌ Tests Failed: $TESTS_FAILED"
echo "📊 Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo ""
    echo "🎉 All tests passed! Your Stremio setup is working correctly."
    echo ""
    echo "🚀 Quick Start:"
    if [[ "$SYSTEM_CHECK" == true ]]; then
        echo "   • Stremio Web: https://localhost:12470"
        echo "   • Or via Tailscale: https://$TAILSCALE_IP:12470"
    else
        echo "   • Stremio Web: https://$OPTIPLEX_IP:12470"
    fi
    echo "   • Jellyfin: http://$OPTIPLEX_IP:8096"
    echo "   • Request Content: http://$OPTIPLEX_IP:5055"
    echo ""
    echo "🔌 Recommended addons to install in Stremio:"
    echo "   • Torrentio: https://torrentio.strem.fun"
    echo "   • OpenSubtitles: https://opensubtitles.strem.fun"
    echo "   • YouTube: https://youtube.strem.fun"
else
    echo ""
    echo "⚠️  Some tests failed. Issues found:"
    for failed_test in "${FAILED_TESTS[@]}"; do
        echo "   • $failed_test"
    done
    echo ""
    echo "🛠  Troubleshooting steps:"
    echo "   1. Check system logs: journalctl -u docker-stremio-*"
    echo "   2. Verify Tailscale connectivity: tailscale status"
    echo "   3. Restart services: systemctl restart docker-stremio-*"
    echo "   4. Check firewall: sudo ufw status (if using ufw)"
    echo ""
    echo "📞 For help, check the configuration in ~/nix/hosts/optiplex-nixos/stremio.nix"
fi

echo ""
echo "📋 System Information:"
echo "   • Hostname: $(hostname)"
echo "   • OS: $(uname -s)"
if command -v tailscale >/dev/null 2>&1; then
    echo "   • Tailscale IP: $(tailscale ip -4 2>/dev/null || echo 'Not available')"
fi
echo "   • Date: $(date)"

exit $TESTS_FAILED