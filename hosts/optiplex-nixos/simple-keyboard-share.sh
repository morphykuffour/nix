#!/usr/bin/env bash
# Simple keyboard/mouse sharing solution using SSH X11 forwarding
# This is a workaround until we get Input Leap portals working

echo "Starting simple keyboard/mouse sharing server..."
echo "Your Mac can connect using:"
echo "  ssh -X morph@optiplex-nixos"
echo ""
echo "Once connected, your Mac's X11 apps will display on optiplex-nixos"
echo "and you can control them with optiplex-nixos keyboard/mouse"
