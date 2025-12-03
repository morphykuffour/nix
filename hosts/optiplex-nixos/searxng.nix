{ config, pkgs, lib, ... }:

{
  # SearXNG meta search engine
  # Runs in Docker container on port 8888
  # Served via Tailscale at https://optiplex-nixos.tailc585e.ts.net/search

  virtualisation.oci-containers.containers.searxng = {
    image = "searxng/searxng:latest";
    autoStart = true;

    ports = [
      "8888:8080"  # SearXNG internal port 8080 → host 8888
    ];

    volumes = [
      "/home/morph/searxng/config:/etc/searxng:rw"
      # Cache stored in Docker volume (managed automatically)
    ];

    environment = {
      # CRITICAL: Tell SearXNG it's served under /search subpath
      # This fixes redirect loops and asset loading
      SEARXNG_BASE_URL = "https://optiplex-nixos.tailc585e.ts.net/search";

      # Redis connection for rate limiting
      SEARXNG_REDIS_URL = "redis://searxng-redis:6379/0";

      # Performance tuning
      UWSGI_WORKERS = "4";
      UWSGI_THREADS = "4";
    };

    # Connect to searxng-redis container
    dependsOn = [ "searxng-redis" ];

    extraOptions = [
      "--network=searxng-network"
    ];
  };

  # Redis backend for SearXNG rate limiting
  virtualisation.oci-containers.containers.searxng-redis = {
    image = "valkey/valkey:8-alpine";
    autoStart = true;

    cmd = [
      "valkey-server"
      "--save"
      "30"
      "1"
      "--loglevel"
      "warning"
    ];

    volumes = [
      "searxng-redis-data:/data"
    ];

    extraOptions = [
      "--network=searxng-network"
      "--health-cmd=valkey-cli ping"
      "--health-interval=30s"
      "--health-timeout=5s"
      "--health-start-period=5s"
    ];
  };

  # Create Docker network for SearXNG containers
  systemd.services.init-searxng-network = {
    description = "Create Docker network for SearXNG";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    before = [ "docker-searxng.service" "docker-searxng-redis.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      ${pkgs.docker}/bin/docker network inspect searxng-network >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create searxng-network
    '';
  };

  # Enable Docker
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
}
