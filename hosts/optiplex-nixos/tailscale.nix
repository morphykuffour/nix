{
  config,
  pkgs,
  agenix,
  inputs,
  ...
}: {

  age.identityPaths = [ "/home/morph/.ssh/id_ed25519" ];
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
      "qbittorrent-nox.service"
      "code-server.service"
      "docker.service"
      "docker-searxng.service"
      "tailscale-set-operator.service"
    ];
    wants = [
      "tailscale.service"
      "qbittorrent-nox.service"
      "code-server.service"
      "docker.service"
      "docker-searxng.service"
      "tailscale-set-operator.service"
    ];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -euc '"+
        # Map qBittorrent under /qbittorrent on 443
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/qbittorrent http://127.0.0.1:8080; " +
        # Map SearXNG under /searx on 443
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/searx http://127.0.0.1:8888; " +
        # VERT UI and assets under paths on 443
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/file-converter http://127.0.0.1:3000; " +
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/_app http://127.0.0.1:3000/_app; " +
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/api http://127.0.0.1:3000/api; " +
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/favicon.png http://127.0.0.1:3000/favicon.png; " +
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/lettermark.jpg http://127.0.0.1:3000/lettermark.jpg; " +
        # Serve code-server directly on its own HTTPS port 8081
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=8081 http://127.0.0.1:8081'";
      ExecStop = "${pkgs.bash}/bin/bash -euc '"+
        "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/qbittorrent off || true; " +
        "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/searx off || true; " +
        "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/file-converter off || true; " +
        "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/_app off || true; " +
        "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/api off || true; " +
        "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/favicon.png off || true; " +
        "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/lettermark.jpg off || true; " +
        "${config.services.tailscale.package}/bin/tailscale serve --https=8081 off || true'";
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
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    # Allow SSH and qBittorrent WebUI only via Tailscale
    allowedTCPPorts = [ 22 ];
    # qBittorrent WebUI (8080) is only accessible via Tailscale serve
  };
}
