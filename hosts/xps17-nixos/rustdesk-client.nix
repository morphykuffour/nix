{
  config,
  pkgs,
  lib,
  ...
}: let
  # RustDesk server on optiplex-nixos
  rustdesk_server_lan = "optiplex-nixos.local"; # LAN hostname (via Avahi/mDNS)
  rustdesk_server_tailscale = "100.89.107.92"; # Tailscale IP

  # Optimal client configuration for low-latency LAN connections
  rustdeskConfig = pkgs.writeText "RustDesk2.toml" ''
    # Server Configuration - Points to optiplex-nixos
    [options]
    # Custom server configuration
    custom-rendezvous-server = "${rustdesk_server_lan}"
    relay-server = ""
    api-server = ""
    key = ""  # Will be filled in after first connection or manually

    # Network Optimization - Maximize LAN performance
    enable-lan-discovery = "Y"           # Allow LAN peers to discover this device
    enable-direct-ip-access = "Y"        # Enable direct IP connectivity (bypass relay)
    direct-access-port = "21118"         # Port for direct connections
    enable-udp-punch = "Y"               # Enable UDP hole punching for P2P
    enable-ipv6-punch = "N"              # Disable IPv6 P2P (usually not needed on LAN)
    disable-udp = "N"                    # Keep UDP enabled for best performance

    # Quality & Performance - Optimized for low latency
    enable-abr = "Y"                     # Adaptive bitrate for network changes
    enable-hwcodec = "Y"                 # Hardware encoding for smooth picture
    enable-directx-capture = "Y"         # DirectX capture (Windows) for better performance
    allow-d3d-render = "N"               # D3D rendering (may cause issues, disabled)

    # Image quality settings - High quality for LAN
    image-quality = "best"               # Use best quality on LAN
    custom-fps = "60"                    # 60 FPS for smooth experience
    codec-preference = "auto"            # Auto-select best codec (h264/h265 on capable hardware)

    # Display rendering optimizations
    use-texture-render = "Y"             # Texture rendering for smoother visuals
    allow-always-software-render = "N"   # Prefer hardware rendering
    i444 = "N"                           # 4:4:4 chroma (disable for better performance)

    # View and UI settings
    view-style = "adaptive"              # Adaptive view style
    scroll-style = "scrollauto"          # Auto-scroll behavior
    show-remote-cursor = "Y"             # Show remote cursor for better UX
    follow-remote-cursor = "N"           # Don't auto-follow cursor
    zoom-cursor = "N"                    # Don't zoom cursor

    # Connection settings
    allow-auto-disconnect = "N"          # Don't auto-disconnect
    keep-screen-on = "during-controlled" # Keep screen on during sessions

    # Security settings - Reasonable defaults
    access-mode = "full"                 # Full access mode
    approve-mode = "password"            # Password-only approval
    verification-method = "use-permanent-password"  # Use permanent password
    enable-keyboard = "Y"
    enable-clipboard = "Y"
    enable-file-transfer = "Y"
    enable-audio = "Y"
    enable-tcp-tunneling = "Y"
    enable-remote-restart = "Y"
    enable-block-input = "N"

    # Recording (disabled by default)
    enable-record-session = "N"
    allow-auto-record-incoming = "N"
    allow-auto-record-outgoing = "N"

    # Device registration
    enable-lan-discovery = "Y"           # Enable LAN discovery
    allow-hostname-as-id = "N"           # Use RustDesk ID instead of hostname
  '';

  # Script to configure RustDesk on first run
  rustdeskSetup = pkgs.writeShellScript "rustdesk-setup.sh" ''
    #!/usr/bin/env bash

    # RustDesk config directory
    CONFIG_DIR="$HOME/.config/rustdesk"
    CONFIG_FILE="$CONFIG_DIR/RustDesk2.toml"

    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"

    # Only copy config if it doesn't exist (don't overwrite user settings)
    if [ ! -f "$CONFIG_FILE" ]; then
      echo "Setting up RustDesk client configuration..."
      cp ${rustdeskConfig} "$CONFIG_FILE"
      chmod 644 "$CONFIG_FILE"
      echo "RustDesk configured to use server: ${rustdesk_server_lan}"
      echo "Tailscale fallback: ${rustdesk_server_tailscale}"
      echo ""
      echo "To use the server, you'll need to add the public key from optiplex-nixos"
      echo "Run on optiplex: ssh optiplex-nixos 'sudo cat /var/lib/rustdesk/id_ed25519.pub'"
    else
      echo "RustDesk config already exists at $CONFIG_FILE"
      echo "To reset to defaults, delete the file and run this script again"
    fi
  '';
in {
  # Network optimizations for low-latency connections
  boot.kernel.sysctl = {
    # Enable TCP Fast Open for lower latency
    "net.ipv4.tcp_fastopen" = 3;

    # Optimize for low latency (reduce bufferbloat)
    "net.ipv4.tcp_low_latency" = 1;

    # Reduce TCP keepalive time for faster detection of dead connections
    "net.ipv4.tcp_keepalive_time" = 600;
    "net.ipv4.tcp_keepalive_intvl" = 60;
    "net.ipv4.tcp_keepalive_probes" = 3;
  };

  # Firewall configuration for RustDesk client
  networking.firewall = {
    # Allow RustDesk direct connection port
    allowedTCPPorts = [21118]; # Direct IP access port
    allowedUDPPorts = [21118]; # Direct IP access port (UDP)
  };

  # Add setup script to system packages for manual configuration
  environment.systemPackages = with pkgs; [
    rustdesk

    # Wrapper script to help users configure RustDesk
    (pkgs.writeScriptBin "rustdesk-configure" ''
      #!${pkgs.bash}/bin/bash
      ${rustdeskSetup}
    '')
  ];

  # User-level service to set up RustDesk config on login (optional)
  systemd.user.services.rustdesk-config-setup = {
    description = "RustDesk Client Configuration Setup";
    wantedBy = ["default.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${rustdeskSetup}";
      RemainAfterExit = true;
    };
  };

  # Add helpful message to login
  environment.interactiveShellInit = ''
    # RustDesk server info
    if [ -f "$HOME/.config/rustdesk/RustDesk2.toml" ]; then
      # Config exists, user is set up
      :
    else
      echo "💡 RustDesk is installed. Run 'rustdesk-configure' to set up your client."
    fi
  '';
}
