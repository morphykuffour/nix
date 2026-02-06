#!/usr/bin/env bash
# Launch VNC with Waydroid and JADENS Printer App
# This script connects to optiplex-nixos via VNC and automatically launches Waydroid

set -e

# Configuration
OPTIPLEX_IP="100.89.107.92"
VNC_PORT="5900"
JADENS_PACKAGE="com.jadens.print"  # Update this with actual package name

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Waydroid VNC Launcher ===${NC}"

# Get current display resolution for dynamic sizing
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - get main display resolution
    DISPLAY_RES=$(system_profiler SPDisplaysDataType | grep Resolution | head -1 | awk '{print $2"x"$4}')
    echo -e "${GREEN}Detected macOS display: ${DISPLAY_RES}${NC}"
else
    # Linux - try xrandr
    DISPLAY_RES=$(xrandr | grep '*' | awk '{print $1}' | head -1)
    echo -e "${GREEN}Detected Linux display: ${DISPLAY_RES}${NC}"
fi

# Function to check if VNC is reachable
check_vnc() {
    nc -z -w 2 "$OPTIPLEX_IP" "$VNC_PORT" 2>/dev/null
}

# Function to wait for VNC connection
wait_for_vnc_ready() {
    echo -e "${BLUE}Checking VNC server...${NC}"
    local max_attempts=5
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if check_vnc; then
            echo -e "${GREEN}VNC server is ready!${NC}"
            return 0
        fi
        echo "Waiting for VNC server... (attempt $((attempt+1))/$max_attempts)"
        sleep 2
        ((attempt++))
    done

    echo "Warning: VNC server not responding, attempting connection anyway..."
    return 1
}

# Function to start Waydroid via SSH
start_waydroid() {
    echo -e "${BLUE}Starting Waydroid session...${NC}"
    ssh optiplex-nixos "WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/run/user/1000 waydroid session start" 2>/dev/null &

    # Wait a bit for session to initialize
    sleep 5

    echo -e "${BLUE}Launching Waydroid UI...${NC}"
    ssh optiplex-nixos "WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/run/user/1000 waydroid show-full-ui" &

    # Wait for Waydroid to fully start
    sleep 10
}

# Function to launch JADENS printer app
launch_jadens_app() {
    echo -e "${BLUE}Attempting to launch JADENS printer app...${NC}"

    # First, check if the app is installed
    if ssh optiplex-nixos "waydroid app list | grep -i jadens || waydroid app list | grep -i print" &>/dev/null; then
        # Try to launch by package name
        ssh optiplex-nixos "waydroid app launch ${JADENS_PACKAGE}" 2>/dev/null || {
            echo -e "${GREEN}App not found with package name. Listing available printer apps:${NC}"
            ssh optiplex-nixos "waydroid app list | grep -i print"
            echo ""
            echo "Please update JADENS_PACKAGE in this script with the correct package name"
        }
    else
        echo -e "${GREEN}JADENS app not installed. Install it using:${NC}"
        echo "  ssh optiplex-nixos 'waydroid app install /path/to/jadens.apk'"
        echo ""
        echo "You can also install it from within Waydroid via:"
        echo "  - Google Play Store (if GAPPS is installed)"
        echo "  - Transfer APK and install manually"
    fi
}

# Main execution
echo -e "${BLUE}Step 1: Checking VNC connection...${NC}"
wait_for_vnc_ready

echo -e "${BLUE}Step 2: Starting Waydroid (this happens in background)...${NC}"
start_waydroid &
WAYDROID_PID=$!

echo -e "${BLUE}Step 3: Launching VNC viewer...${NC}"
echo "  - Window size: 1920x1080"
echo "  - Remote desktop will resize to fit"
echo ""

# Launch VNC with optimal window size that shows full display
vncviewer \
    -RemoteResize=1 \
    -geometry 1920x1080 \
    -QualityLevel=8 \
    -CompressLevel=2 \
    -AcceptClipboard=1 \
    -SendClipboard=1 \
    -DotWhenNoCursor=0 \
    -PointerEventInterval=10 \
    "${OPTIPLEX_IP}:${VNC_PORT}" &

VNC_PID=$!

# Wait a bit for VNC window to appear and connect
sleep 8

echo -e "${BLUE}Step 4: Launching JADENS printer app...${NC}"
launch_jadens_app

echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo "VNC viewer is running (PID: $VNC_PID)"
echo "Waydroid should be visible in the VNC session"
echo ""
echo "Useful commands:"
echo "  - List apps:     ssh optiplex-nixos 'waydroid app list'"
echo "  - Install APK:   ssh optiplex-nixos 'waydroid app install /path/to/app.apk'"
echo "  - Stop Waydroid: ssh optiplex-nixos 'waydroid session stop'"
echo ""
echo "To close everything, close the VNC viewer window or press Ctrl+C"

# Wait for VNC viewer to exit
wait $VNC_PID 2>/dev/null || true

echo -e "${BLUE}Cleaning up...${NC}"
# VNC viewer closed, optionally stop Waydroid
read -p "Stop Waydroid session? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ssh optiplex-nixos "waydroid session stop"
    echo "Waydroid stopped"
fi

echo -e "${GREEN}Done!${NC}"
