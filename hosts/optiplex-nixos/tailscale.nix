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

  # Advertise qBittorrent WebUI as a Tailscale service
  systemd.services.tailscale-serve-qbittorrent = {
    description = "Advertise qBittorrent WebUI on Tailscale";
    after = ["tailscale.service" "qbittorrent-nox.service" "tailscale-set-operator.service"];
    wants = ["tailscale.service" "qbittorrent-nox.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/qbittorrent http://127.0.0.1:8080";
      ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=443 off";
    };
  };

  # Advertise SearXNG as a Tailscale service (under /searx to avoid shadowing /)
  systemd.services.tailscale-serve-searxng = {
    description = "Advertise SearXNG on Tailscale";
    after = ["tailscale.service" "docker-searxng.service" "tailscale-set-operator.service"];
    wants = ["tailscale.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/searx http://127.0.0.1:8888";
      ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/searx off";
    };
  };

  # Advertise VERT (Docker UI on host:3000) via Tailscale under /file-converter and proxy asset paths
  systemd.services.tailscale-serve-vert = {
    description = "Advertise VERT UI on Tailscale";
    after = ["tailscale.service" "docker.service" "tailscale-set-operator.service" "tailscale-serve-searxng.service"];
    wants = ["tailscale.service" "docker.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -euc '"+
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/file-converter http://127.0.0.1:3000; " +
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/_app http://127.0.0.1:3000/_app; " +
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/api http://127.0.0.1:3000/api; " +
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/favicon.png http://127.0.0.1:3000/favicon.png; " +
        "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/lettermark.jpg http://127.0.0.1:3000/lettermark.jpg'";
      ExecStop = "${pkgs.bash}/bin/bash -euc '"+
        "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/file-converter off || true; " +
        "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/_app off || true; " +
        "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/api off || true; " +
        "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/favicon.png off || true; " +
        "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/lettermark.jpg off || true'";
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
