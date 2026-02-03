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

  # Systemd user service for Deskflow client
  systemd.user.services.deskflow-client = {
    description = "Deskflow Client - Keyboard/Mouse Sharing";
    wantedBy = [ "sway-session.target" ];
    after = [ "sway-session.target" ];
    partOf = [ "sway-session.target" ];

    serviceConfig = {
      Type = "simple";
      # Run Deskflow in client mode
      # -f = run in foreground
      # -d INFO = logging level
      # -n = client name
      # Connect to macmini-darwin server on Tailscale or local network
      ExecStart = "${pkgs.deskflow}/bin/deskflow-client -f -d INFO -n optiplex-nixos macmini-darwin:24800";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    environment = {
      DISPLAY = ":0";
      WAYLAND_DISPLAY = "wayland-1";
      XDG_RUNTIME_DIR = "/run/user/1000";
    };
  };

  # Firewall configuration - client mode doesn't need incoming connections
  # No firewall rules needed for client (only makes outgoing connections to server)

  # Helper script for Deskflow client
  environment.etc."profile.d/deskflow-helper.sh".text = ''
    # Deskflow client helpers
    alias deskflow-status='systemctl --user status deskflow-client'
    alias deskflow-restart='systemctl --user restart deskflow-client'
    alias deskflow-logs='journalctl --user -u deskflow-client -f'
    alias deskflow-stop='systemctl --user stop deskflow-client'
    alias deskflow-start='systemctl --user start deskflow-client'
  '';
}
