{ config, pkgs, lib, ... }:

{
  # VERT file converter Docker container
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
}
