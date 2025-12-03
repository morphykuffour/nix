{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable vertd service for video conversion
  # Use the package from our overlay which has proper OpenSSL support
  # Since we're bypassing the vertd flake module, define the service manually
  systemd.services.vertd = {
    description = "VERT's solution to video conversion";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.vertd}/bin/vertd --port 24153";
      Restart = "on-failure";
      RestartSec = "10s";
      # Security settings
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = false;
      ReadWritePaths = [ "/tmp" ];
    };
    
    environment = {
      # Ensure ffmpeg is available - use mkForce to override default PATH
      PATH = lib.mkForce (lib.makeBinPath [ 
        pkgs.ffmpeg-full 
        pkgs.coreutils 
        pkgs.findutils 
        pkgs.gnugrep 
        pkgs.gnused 
        pkgs.systemd 
      ]);
    };
  };

  # Open firewall port for vertd
  networking.firewall.allowedTCPPorts = [24153];

  # Ensure ffmpeg is available system-wide for vertd
  environment.systemPackages = with pkgs; [
    ffmpeg-full
  ];
}
