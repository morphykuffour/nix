{
  config,
  pkgs,
  lib,
  ...
}: {
  # Deskflow (formerly Synergy) - Share keyboard/mouse across computers

  # Install Deskflow
  environment.systemPackages = with pkgs; [
    barrier  # Open source Synergy fork (works like Deskflow)
  ];

  # Systemd user service for Barrier server
  systemd.user.services.barrier-server = {
    description = "Barrier Server - Keyboard/Mouse Sharing";
    wantedBy = [ "sway-session.target" ];
    after = [ "sway-session.target" ];
    partOf = [ "sway-session.target" ];

    serviceConfig = {
      Type = "simple";
      # Run Barrier in server mode
      # -f = run in foreground
      # --no-tray = don't show tray icon
      # --debug INFO = logging level
      # --name = server name
      # --enable-crypto = SSL encryption
      # --address :24800 = listen on all interfaces, port 24800
      ExecStart = "${pkgs.barrier}/bin/barriers -f --no-tray --debug INFO --name optiplex-nixos --address :24800";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    environment = {
      DISPLAY = ":0";
      WAYLAND_DISPLAY = "wayland-1";
      XDG_RUNTIME_DIR = "/run/user/1000";
    };
  };

  # Firewall configuration - allow Barrier on Tailscale AND local network
  networking.firewall = {
    # Allow on Tailscale
    interfaces.tailscale0 = {
      allowedTCPPorts = [
        24800  # Barrier/Synergy default port
      ];
    };
    # Also allow on main network interface for local LAN access
    interfaces.enp0s31f6 = {
      allowedTCPPorts = [
        24800  # Barrier/Synergy default port
      ];
    };
  };

  # Create default Barrier config
  environment.etc."barrier-server-config".text = ''
section: screens
    optiplex-nixos:
    macmini-darwin:
end

section: links
    optiplex-nixos:
        right = macmini-darwin
    macmini-darwin:
        left = optiplex-nixos
end

section: options
    keystroke(Super+L) = switchInDirection(right)
    keystroke(Super+H) = switchInDirection(left)
end
  '';

  # Helper script to set up Barrier config
  environment.etc."profile.d/barrier-helper.sh".text = ''
    # Barrier helpers
    alias barrier-status='systemctl --user status barrier-server'
    alias barrier-restart='systemctl --user restart barrier-server'
    alias barrier-logs='journalctl --user -u barrier-server -f'

    # Create Barrier config if it doesn't exist
    if [ ! -f ~/.config/barrier/barrier.conf ]; then
        mkdir -p ~/.config/barrier
        cp /etc/barrier-server-config ~/.config/barrier/barrier.conf
        echo "Barrier config created at ~/.config/barrier/barrier.conf"
    fi
  '';
}
