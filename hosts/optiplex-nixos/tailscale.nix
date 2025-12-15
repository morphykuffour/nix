{
  config,
  pkgs,
  agenix,
  inputs,
  ...
}: {
  age.identityPaths = ["/home/morph/.ssh/id_ed25519"];
  age.secrets.ts-optiplex-nixos.file = ../../secrets/ts-optiplex-nixos.age;
  age.secrets.qbittorrent-webui-password = {
    file = ../../secrets/qbittorrent-optiplex-nixos.age;
    owner = "morph";
    group = "users";
    mode = "0400";
  };

  services.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets.ts-optiplex-nixos.path;
    extraUpFlags = [
      "--advertise-exit-node"
      "--ssh"
      # optional if you've experimented before:
      # "--reset"
    ];
  };

  # Allow morph user to manage Tailscale serve without sudo
  systemd.services.tailscale-set-operator = {
    description = "Set Tailscale operator to allow non-root serve management";
    after = ["tailscale.service"];
    wants = ["tailscale.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.services.tailscale.package}/bin/tailscale set --operator=morph";
    };
  };

  # Consolidated Tailscale Serve configuration to avoid ETag conflicts
  systemd.services.tailscale-serve-config = {
    description = "Configure all Tailscale serve routes atomically";
    after = [
      "tailscale.service"
      "docker-gluetun.service"
      "docker-qbittorrent.service"
      "docker-radarr.service"
      "docker-sonarr.service"
      "docker-lidarr.service"
      "docker-bazarr.service"
      "docker-prowlarr.service"
      "docker-jellyseerr.service"
      "docker-flaresolverr.service"
      "code-server.service"
      "docker.service"
      "docker-vert.service"
      "tailscale-set-operator.service"
    ];
    wants = [
      "tailscale.service"
      "docker-gluetun.service"
      "docker-qbittorrent.service"
      "docker-radarr.service"
      "docker-sonarr.service"
      "docker-lidarr.service"
      "docker-bazarr.service"
      "docker-prowlarr.service"
      "docker-jellyseerr.service"
      "docker-flaresolverr.service"
      "code-server.service"
      "docker.service"
      "docker-vert.service"
      "tailscale-set-operator.service"
    ];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart =
        "${pkgs.bash}/bin/bash -euc '"
        +
        # Media Stack Services (via Gluetun-exposed ports)
        # Map qBittorrent under /qbittorrent on 443
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/qbittorrent http://127.0.0.1:8701; "
        +
        # Radarr on dedicated HTTPS port 7878
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=7878 http://127.0.0.1:7878; "
        +
        # Sonarr on dedicated HTTPS port 8989
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=8989 http://127.0.0.1:8989; "
        +
        # Lidarr on dedicated HTTPS port 8686
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=8686 http://127.0.0.1:8686; "
        +
        # Bazarr on dedicated HTTPS port 6767
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=6767 http://127.0.0.1:6767; "
        +
        # Prowlarr on dedicated HTTPS port 9696
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=9696 http://127.0.0.1:9696; "
        +
        # FlareSolverr on dedicated HTTPS port 8191
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=8191 http://127.0.0.1:8191; "
        +
        # Jellyseerr on dedicated HTTPS port 5055
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=5055 http://127.0.0.1:5055; "
        +
        # Other Services
        # Serve SearXNG on BOTH /search subpath AND dedicated port 8443
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/search http://127.0.0.1:8888; "
        + "${config.services.tailscale.package}/bin/tailscale serve --bg --https=8443 http://127.0.0.1:8888; "
        +
        # Serve VERT UI on its own HTTPS port 444 to avoid subpath/asset rewrites
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=444 http://127.0.0.1:3000; "
        +
        # Serve code-server directly on its own HTTPS port 8081
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=8081 http://127.0.0.1:8081; "
        +
        # Serve vertd backend API on its own HTTPS port 24153
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=24153 http://127.0.0.1:24153'";
      ExecStop =
        "${pkgs.bash}/bin/bash -euc '"
        + "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/qbittorrent off || true; "
        + "${config.services.tailscale.package}/bin/tailscale serve --https=7878 off || true; "
        + "${config.services.tailscale.package}/bin/tailscale serve --https=8989 off || true; "
        + "${config.services.tailscale.package}/bin/tailscale serve --https=8686 off || true; "
        + "${config.services.tailscale.package}/bin/tailscale serve --https=6767 off || true; "
        + "${config.services.tailscale.package}/bin/tailscale serve --https=9696 off || true; "
        + "${config.services.tailscale.package}/bin/tailscale serve --https=8191 off || true; "
        + "${config.services.tailscale.package}/bin/tailscale serve --https=5055 off || true; "
        + "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/search off || true; "
        + "${config.services.tailscale.package}/bin/tailscale serve --https=8443 off || true; "
        + "${config.services.tailscale.package}/bin/tailscale serve --https=444 off || true; "
        + "${config.services.tailscale.package}/bin/tailscale serve --https=8081 off || true; "
        + "${config.services.tailscale.package}/bin/tailscale serve --https=24153 off || true'";
    };
  };

  # Good practice for exit nodes
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.firewall = {
    enable = true;
    checkReversePath = "loose";
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [config.services.tailscale.port];
    # Allow SSH and qBittorrent WebUI only via Tailscale
    allowedTCPPorts = [22];
    # qBittorrent WebUI (8701) is only accessible via Tailscale serve
  };
}
