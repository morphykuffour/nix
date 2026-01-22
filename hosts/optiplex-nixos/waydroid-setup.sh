#!/usr/bin/env bash
# Waydroid helper script for optiplex-nixos
# This script helps manage waydroid and ensures it starts correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if waydroid is running
check_status() {
    echo -e "${YELLOW}Checking waydroid status...${NC}"
    waydroid status
}

# Start waydroid session
start_session() {
    echo -e "${YELLOW}Starting waydroid session...${NC}"
    if ! pgrep -f "waydroid session start" > /dev/null; then
        waydroid session start &
        sleep 5
    else
        echo -e "${GREEN}Waydroid session already running${NC}"
    fi
}

# Show full UI
show_ui() {
    echo -e "${YELLOW}Showing waydroid UI...${NC}"
    waydroid show-full-ui &
}

# Launch Play Store
launch_playstore() {
    echo -e "${YELLOW}Launching Google Play Store...${NC}"
    waydroid app launch com.android.vending
}

# List installed apps
list_apps() {
    echo -e "${YELLOW}Installed apps:${NC}"
    waydroid app list
}

# Install APK
install_apk() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Please provide path to APK file${NC}"
        echo "Usage: $0 install /path/to/app.apk"
        exit 1
    fi
    echo -e "${YELLOW}Installing APK: $1${NC}"
    waydroid app install "$1"
}

# Stop waydroid
stop_session() {
    echo -e "${YELLOW}Stopping waydroid session...${NC}"
    waydroid session stop
}

# Main menu
case "${1:-status}" in
    status)
        check_status
        ;;
    start)
        start_session
        check_status
        ;;
    ui)
        show_ui
        ;;
    playstore)
        launch_playstore
        ;;
    list)
        list_apps
        ;;
    install)
        install_apk "$2"
        ;;
    stop)
        stop_session
        ;;
    setup)
        echo -e "${GREEN}=== Waydroid Setup for Jadens Label Printing ===${NC}"
        echo ""
        echo "1. Starting waydroid session..."
        start_session
        echo ""
        echo "2. Showing waydroid UI..."
        show_ui
        echo ""
        echo -e "${YELLOW}Next steps:${NC}"
        echo "  - Open Play Store in waydroid"
        echo "  - Search for 'Jadens' or the label printing app"
        echo "  - Install and configure the app"
        echo "  - Connect your label printer via USB or Bluetooth"
        echo ""
        echo -e "${GREEN}To launch Play Store:${NC} $0 playstore"
        ;;
    *)
        echo "Waydroid Helper Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  status      - Check waydroid status (default)"
        echo "  start       - Start waydroid session"
        echo "  ui          - Show waydroid full UI"
        echo "  playstore   - Launch Google Play Store"
        echo "  list        - List installed apps"
        echo "  install APK - Install an APK file"
        echo "  stop        - Stop waydroid session"
        echo "  setup       - Run initial setup for Jadens app"
        ;;
esac
