{
  config,
  pkgs,
  ...
}: {
  # Enable vertd service for video conversion
  # Use the package from our overlay which has proper OpenSSL support
  services.vertd = {
    enable = true;
    port = 24153; # Default port for vertd
    package = pkgs.vertd; # Explicitly use the overridden package
  };

  # Open firewall port for vertd
  networking.firewall.allowedTCPPorts = [24153];

  # Ensure ffmpeg is available system-wide for vertd
  environment.systemPackages = with pkgs; [
    ffmpeg-full
  ];
}
