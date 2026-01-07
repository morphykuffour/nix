# Remote Desktop configuration for headless Wayland access
# - Passwordless RustDesk for Tailscale network
# - Virtual Wayland display for headless operation
# - Auto-start on boot
{
  config,
  pkgs,
  lib,
  ...
}: let
  # RustDesk server configuration (self-hosted on this machine)
  rustdesk_server = "100.89.107.92";
  rustdesk_key = "sOIwLVZhj6oBdKBD7kaK5YE5+k5EpQWNNMjiAfGkyec=";

  # Tailscale CIDR for whitelist (passwordless access)
  tailscale_cidr = "100.64.0.0/10";

  # RustDesk client config - passwordless for Tailscale
  rustdeskConfig = pkgs.writeText "RustDesk2.toml" ''
    rendezvous_server = '${rustdesk_server}:21115'
    nat_type = 1
    serial = 0

    [options]
    custom-rendezvous-server = '${rustdesk_server}:21115'
    relay-server = '${rustdesk_server}:21117'
    key = '${rustdesk_key}'

    # Passwordless for Tailscale network - auto-accept connections
    approve-mode = 'click'
    verification-method = 'use-permanent-password'

    # Whitelist Tailscale network for passwordless access
    whitelist = '${tailscale_cidr}'

    # Enable direct IP access (for Tailscale direct connections)
    enable-lan-discovery = 'Y'
    enable-direct-ip-access = 'Y'
    direct-access-port = '21118'

    # Quality settings for good remote experience
    image-quality = 'best'
    custom-fps = '30'

    # Full access permissions
    access-mode = 'full'
    enable-keyboard = 'Y'
    enable-clipboard = 'Y'
    enable-file-transfer = 'Y'
    enable-audio = 'Y'
  '';

  # Script to set up RustDesk config and start server
  rustdeskSetup = pkgs.writeShellScript "rustdesk-wayland-setup" ''
    set -e
    CONFIG_DIR="$HOME/.config/rustdesk"
    mkdir -p "$CONFIG_DIR"

    # Copy config
    cp ${rustdeskConfig} "$CONFIG_DIR/RustDesk2.toml"
    chmod 600 "$CONFIG_DIR/RustDesk2.toml"

    # Set permanent password from agenix secret
    if [ -f "/run/agenix/vnc-optiplex-nixos" ]; then
      PASSWORD=$(cat /run/agenix/vnc-optiplex-nixos)
      ${pkgs.rustdesk}/bin/rustdesk --password "$PASSWORD" 2>/dev/null || true
    fi

    echo "RustDesk configured for Wayland with Tailscale whitelist"
  '';
in {
  # ============================================
  # AGENIX SECRET - Remote Desktop Password
  # ============================================
  age.secrets.vnc-optiplex-nixos = {
    file = ../../secrets/vnc-optiplex-nixos.age;
    owner = "morph";
    group = "users";
    mode = "0400";
  };

  # ============================================
  # VIRTUAL DISPLAY - Headless Wayland support
  # ============================================
  # For headless operation, GNOME/mutter can create virtual outputs
  # This is configured via mutter settings

  # Enable GNOME's headless/virtual display support
  services.xserver.displayManager.gdm = {
    enable = true;
    wayland = true;
    autoSuspend = false;
  };

  # Configure mutter for virtual displays
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/mutter" = {
        experimental-features = ["scale-monitor-framebuffer" "kms-modifiers"];
      };
      # Prevent screen blanking
      "org/gnome/desktop/session" = {
        idle-delay = lib.gvariant.mkUint32 0;
      };
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-battery-type = "nothing";
        power-button-action = "nothing";
      };
      # Disable screen lock
      "org/gnome/desktop/screensaver" = {
        lock-enabled = false;
        idle-activation-enabled = false;
      };
    };
  }];

  # ============================================
  # AUTO-LOGIN - Ensure graphical session is always active
  # ============================================
  services.displayManager.autoLogin = {
    enable = true;
    user = "morph";
  };

  # Workaround for GNOME auto-login race condition
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # ============================================
  # RUSTDESK CLIENT - Wayland with passwordless Tailscale
  # ============================================
  systemd.user.services.rustdesk-client = {
    description = "RustDesk Client for Wayland Remote Access";
    wantedBy = ["graphical-session.target"];
    after = ["graphical-session.target" "pipewire.service"];

    serviceConfig = {
      Type = "simple";
      ExecStartPre = "${rustdeskSetup}";
      ExecStart = "${pkgs.rustdesk}/bin/rustdesk --server";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    environment = {
      # Wayland environment
      WAYLAND_DISPLAY = "wayland-0";
      XDG_SESSION_TYPE = "wayland";
      # For PipeWire screen capture
      XDG_CURRENT_DESKTOP = "GNOME";
    };
  };

  # ============================================
  # FIREWALL - RustDesk ports via Tailscale
  # ============================================
  networking.firewall = {
    interfaces.tailscale0 = {
      allowedTCPPorts = [
        21118  # RustDesk direct access
        21119  # RustDesk
        3389   # RDP (fallback)
      ];
      allowedUDPPorts = [
        21118  # RustDesk direct access
      ];
    };
  };

  # ============================================
  # PACKAGES
  # ============================================
  environment.systemPackages = with pkgs; [
    rustdesk

    # Screen/display tools
    wdisplays      # Wayland display configuration
    wl-clipboard   # Wayland clipboard

    # For debugging
    wlr-randr      # Wayland output management
  ];

  # ============================================
  # DISPLAY CONFIGURATION
  # ============================================
  # Keep display active for remote access
  services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
    powerKey = "ignore";
    powerKeyLongPress = "ignore";
    settings = {
      Login = {
        IdleAction = "ignore";
        IdleActionSec = 0;
      };
    };
  };

  # ============================================
  # PIPEWIRE - Required for Wayland screen capture
  # ============================================
  # PipeWire is needed for RustDesk to capture Wayland screens
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Portal for screen sharing (required for Wayland)
  xdg.portal = {
    enable = true;
    wlr.enable = false;  # Not needed for GNOME
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  # ============================================
  # HELPER SCRIPTS
  # ============================================
  environment.etc."profile.d/remote-desktop-helper.sh".text = ''
    # RustDesk helpers
    alias rustdesk-id='rustdesk --get-id'
    alias rustdesk-server='rustdesk --server'
    alias rustdesk-status='systemctl --user status rustdesk-client'
    alias rustdesk-restart='systemctl --user restart rustdesk-client'

    # Display helpers
    alias list-displays='wlr-randr'
  '';
}
