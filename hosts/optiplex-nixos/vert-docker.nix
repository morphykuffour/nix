{ config, pkgs, lib, ... }:

{
  # VERT file converter Docker container
  # Note: Pre-built images have environment vars baked in at build time
  # To connect to local vertd, we need to either:
  # 1. Build custom image with PUB_VERTD_URL pointing to local backend
  # 2. Use Tailscale to expose vertd and configure it in the web UI

  virtualisation.oci-containers.containers.vert = {
    image = "ghcr.io/vert-sh/vert:latest";
    autoStart = true;
    ports = [ "3000:80" ];
    extraOptions = [
      "--health-cmd=curl --fail --silent --output /dev/null http://localhost || exit 1"
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-start-period=5s"
    ];
  };

  # Enable Docker/OCI containers
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  # Ensure git is available for building custom VERT image if needed
  environment.systemPackages = with pkgs; [ git ];
}
