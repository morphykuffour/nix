{
  config,
  pkgs,
  lib,
  ...
}: {
  # Deskflow (formerly Synergy/Barrier) - Share keyboard/mouse across computers

  # Install Deskflow
  environment.systemPackages = with pkgs; [
    deskflow  # Keyboard/mouse sharing across computers
  ];

  # Systemd user service for Deskflow server
  systemd.user.services.deskflow-server = {
    description = "Deskflow Server - Keyboard/Mouse Sharing";
    wantedBy = [ "sway-session.target" ];
    after = [ "sway-session.target" ];
    partOf = [ "sway-session.target" ];

    serviceConfig = {
      Type = "simple";
      # Run Deskflow in server mode
      # -f = run in foreground
      # --no-tray = don't show tray icon
      # --debug INFO = logging level
      # --name = server name
      # --enable-crypto = SSL encryption
      # --address :24800 = listen on all interfaces, port 24800
      ExecStart = "${pkgs.deskflow}/bin/deskflows -f --no-tray --debug INFO --name optiplex-nixos --address :24800";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    environment = {
      DISPLAY = ":0";
      WAYLAND_DISPLAY = "wayland-1";
      XDG_RUNTIME_DIR = "/run/user/1000";
    };
  };

  # Firewall configuration - allow Deskflow on Tailscale AND local network
  networking.firewall = {
    # Allow on Tailscale
    interfaces.tailscale0 = {
      allowedTCPPorts = [
        24800  # Deskflow/Synergy default port
      ];
    };
    # Also allow on main network interface for local LAN access
    interfaces.enp0s31f6 = {
      allowedTCPPorts = [
        24800  # Deskflow/Synergy default port
      ];
    };
  };

  # Create default Deskflow config
  environment.etc."deskflow-server-config".text = ''
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

  # Helper script to set up Deskflow config
  environment.etc."profile.d/deskflow-helper.sh".text = ''
    # Deskflow helpers
    alias deskflow-status='systemctl --user status deskflow-server'
    alias deskflow-restart='systemctl --user restart deskflow-server'
    alias deskflow-logs='journalctl --user -u deskflow-server -f'

    # Create Deskflow config if it doesn't exist
    if [ ! -f ~/.config/deskflow/deskflow.conf ]; then
        mkdir -p ~/.config/deskflow
        cp /etc/deskflow-server-config ~/.config/deskflow/deskflow.conf
        echo "Deskflow config created at ~/.config/deskflow/deskflow.conf"
    fi
  '';
}
