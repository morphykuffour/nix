{
  config,
  pkgs,
  lib,
  ...
}: {
  # Input Leap (Synergy fork) - Share keyboard/mouse across computers

  # Install Input Leap
  environment.systemPackages = with pkgs; [
    input-leap  # Keyboard/mouse sharing across computers
  ];

  # Systemd user service for Input Leap client
  systemd.user.services.deskflow-client = {
    description = "Input Leap Client - Keyboard/Mouse Sharing";
    wantedBy = [ "sway-session.target" ];
    after = [ "sway-session.target" ];
    partOf = [ "sway-session.target" ];

    serviceConfig = {
      Type = "simple";
      # Run Input Leap in client mode
      # -f = run in foreground
      # --no-tray = don't show tray icon
      # --debug INFO = logging level
      # --name = client name
      # Connect to macmini-darwin server on Tailscale or local network
      ExecStart = "${pkgs.input-leap}/bin/input-leapc -f --no-tray --debug INFO --name optiplex-nixos macmini-darwin:24800";
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

  # Helper script for Input Leap client
  environment.etc."profile.d/deskflow-helper.sh".text = ''
    # Input Leap client helpers (using deskflow-* aliases for consistency)
    alias deskflow-status='systemctl --user status deskflow-client'
    alias deskflow-restart='systemctl --user restart deskflow-client'
    alias deskflow-logs='journalctl --user -u deskflow-client -f'
    alias deskflow-stop='systemctl --user stop deskflow-client'
    alias deskflow-start='systemctl --user start deskflow-client'
    alias input-leap-status='systemctl --user status deskflow-client'
    alias input-leap-restart='systemctl --user restart deskflow-client'
    alias input-leap-logs='journalctl --user -u deskflow-client -f'
  '';
}
