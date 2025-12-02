{
  config,
  pkgs,
  ...
}: {
  # Enable vertd service for video conversion
  services.vertd = {
    enable = true;
    port = 24153; # Default port for vertd
  };

  # Open firewall port for vertd
  networking.firewall.allowedTCPPorts = [24153];

  # Ensure ffmpeg is available system-wide for vertd
  environment.systemPackages = with pkgs; [
    ffmpeg-full
  ];
}
