# VNC Server configuration for remote access from iPhone
# Uses GNOME Remote Desktop (gnome-remote-desktop) for Wayland-native VNC
# Only accessible via Tailscale network
{
  config,
  pkgs,
  lib,
  ...
}: let
  # Script to configure VNC password from agenix secret
  configureVncPassword = pkgs.writeShellScript "configure-vnc-password" ''
    set -e
    PASSWORD_FILE="${config.age.secrets.vnc-optiplex-nixos.path}"

    if [ -f "$PASSWORD_FILE" ]; then
      PASSWORD=$(cat "$PASSWORD_FILE")
      # Use grd-ctl to set VNC password (GNOME Remote Desktop control tool)
      ${pkgs.gnome-remote-desktop}/bin/grd-ctl vnc set-password "$PASSWORD" 2>/dev/null || true
      ${pkgs.gnome-remote-desktop}/bin/grd-ctl vnc enable 2>/dev/null || true
      ${pkgs.gnome-remote-desktop}/bin/grd-ctl vnc set-auth-method password 2>/dev/null || true
      echo "VNC password configured from secret"
    else
      echo "Warning: VNC password secret not found at $PASSWORD_FILE"
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
  # SYSTEMD - Configure VNC password on boot
  # ============================================
  systemd.services.configure-vnc-password = {
    description = "Configure GNOME Remote Desktop VNC password";
    after = ["agenix.service" "graphical.target"];
    wantedBy = ["graphical.target"];

    serviceConfig = {
      Type = "oneshot";
      User = "morph";
      Group = "users";
      ExecStart = "${configureVncPassword}";
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

    # VNC client for local testing
    tigervnc

    # Screen configuration
    wdisplays # Wayland display configuration
  ];

  # ============================================
  # USER SERVICE - Configure VNC on login
  # ============================================
  # Create a helper script for manual setup if needed
  environment.etc."profile.d/vnc-setup-helper.sh".text = ''
    # Helper to check VNC status
    alias vnc-status='systemctl --user status gnome-remote-desktop'
    alias vnc-enable='systemctl --user enable --now gnome-remote-desktop'
    alias vnc-password='grd-ctl vnc set-password'
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
