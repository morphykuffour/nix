# Remote Desktop configuration for iPhone access
# Uses GNOME Remote Desktop (RDP) or RustDesk for Wayland
# Only accessible via Tailscale network
{
  config,
  pkgs,
  lib,
  ...
}: let
  # Script to configure RDP credentials from agenix secret
  configureRdp = pkgs.writeShellScript "configure-rdp" ''
    set -e
    PASSWORD_FILE="${config.age.secrets.vnc-optiplex-nixos.path}"
    GRDCTL="${pkgs.gnome-remote-desktop}/bin/grdctl"

    if [ -f "$PASSWORD_FILE" ]; then
      PASSWORD=$(cat "$PASSWORD_FILE")
      # Configure RDP (GNOME Remote Desktop 49+ only supports RDP, not VNC)
      "$GRDCTL" rdp enable 2>/dev/null || true
      "$GRDCTL" rdp disable-view-only 2>/dev/null || true
      "$GRDCTL" rdp set-credentials morph "$PASSWORD" 2>/dev/null || true
      echo "RDP configured (note: GNOME keyring must be unlocked from GUI)"
    else
      echo "Warning: Password secret not found at $PASSWORD_FILE"
    fi
  '';
in {
  # ============================================
  # AGENIX SECRET - VNC Password
  # ============================================
  age.secrets.vnc-optiplex-nixos = {
    file = ../../secrets/vnc-optiplex-nixos.age;
    owner = "morph";
    group = "users";
    mode = "0400";
  };

  # ============================================
  # GNOME REMOTE DESKTOP - Native Wayland VNC
  # ============================================
  services.gnome.gnome-remote-desktop.enable = true;

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
  # SYSTEMD - Configure RDP on boot
  # ============================================
  systemd.services.configure-rdp = {
    description = "Configure GNOME Remote Desktop RDP";
    after = ["agenix.service" "graphical.target"];
    wantedBy = ["graphical.target"];

    serviceConfig = {
      Type = "oneshot";
      User = "morph";
      Group = "users";
      ExecStart = "${configureRdp}";
      RemainAfterExit = true;
    };

    environment = {
      HOME = "/home/morph";
      XDG_RUNTIME_DIR = "/run/user/1000";
      DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
    };
  };

  # ============================================
  # FIREWALL - VNC only via Tailscale
  # ============================================
  networking.firewall = {
    # VNC port 5900 - only allow from Tailscale
    interfaces.tailscale0 = {
      allowedTCPPorts = [
        5900 # VNC
        3389 # RDP (alternative)
      ];
    };
  };

  # ============================================
  # PACKAGES
  # ============================================
  environment.systemPackages = with pkgs; [
    gnome-remote-desktop

    # RustDesk - Wayland-compatible remote desktop (uses PipeWire screen capture)
    # Connect using RustDesk iOS app or via Tailscale IP directly
    rustdesk

    # VNC client for local testing
    tigervnc

    # Screen configuration
    wdisplays # Wayland display configuration
  ];

  # ============================================
  # USER SERVICE - Configure RDP/Remote Desktop on login
  # ============================================
  # Create a helper script for manual setup if needed
  environment.etc."profile.d/remote-desktop-helper.sh".text = ''
    # Helper commands for remote desktop
    alias rdp-status='systemctl --user status gnome-remote-desktop'
    alias rdp-enable='systemctl --user enable --now gnome-remote-desktop'
    alias grdctl='${pkgs.gnome-remote-desktop}/bin/grdctl'

    # RustDesk helper - start with screen sharing permission prompt
    alias rustdesk-server='rustdesk --server'
  '';

  # ============================================
  # DISPLAY CONFIGURATION
  # ============================================
  # Keep display active for remote access
  services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
  };

  # Prevent screen blanking
  services.xserver.displayManager.gdm.autoSuspend = false;
}
