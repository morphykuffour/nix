# VNC Server configuration for remote access from iPhone
# Uses GNOME Remote Desktop (gnome-remote-desktop) for Wayland-native VNC
# Only accessible via Tailscale network
{
  config,
  pkgs,
  lib,
  ...
}: {
  # VNC password is configured manually via GNOME Settings > Sharing > Remote Desktop
  # This ensures no secrets are stored in the Nix configuration
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
  # Note: gnome-remote-desktop configuration is per-user
  # The user needs to enable it via GNOME Settings > Sharing > Remote Desktop
  # Or we can automate it with dconf/gsettings

  # Create a helper script for initial setup
  environment.etc."profile.d/vnc-setup-helper.sh".text = ''
    # Helper to check VNC status
    alias vnc-status='systemctl --user status gnome-remote-desktop'
    alias vnc-enable='systemctl --user enable --now gnome-remote-desktop'

    # First-time setup reminder
    if [ ! -f "$HOME/.config/gnome-remote-desktop/.vnc-configured" ]; then
      echo ""
      echo "=== VNC Setup Required ==="
      echo "Run these commands to enable VNC:"
      echo "  1. Open GNOME Settings > Sharing > Remote Desktop"
      echo "  2. Enable 'Remote Desktop' and 'Remote Control'"
      echo "  3. Set authentication method and password"
      echo ""
      echo "Or run: gnome-remote-desktop-configure"
      echo ""
    fi
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
