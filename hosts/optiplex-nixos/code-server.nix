{
  config,
  pkgs,
  ...
}: {
  # code-server configuration
  services.code-server = {
    enable = true;
    user = "morph";
    group = "users";
    host = "127.0.0.1";
    port = 8081; # Using 8081 since qBittorrent uses 8080
    auth = "none"; # Tailscale provides authentication
    extraEnvironment = {
      CS_DISABLE_GETTING_STARTED_OVERRIDE = "1";
    };
  };

  # Caddy as a local reverse proxy to handle path rewriting
  services.caddy = {
    enable = true;
    # Run on a different port since Tailscale is using 443
    # Use http:// to disable automatic HTTPS
    virtualHosts."http://127.0.0.1:8082".extraConfig = ''
      handle_path /code-server* {
        reverse_proxy 127.0.0.1:8081
      }
    '';
  };

  # Advertise Caddy (with code-server behind it) via Tailscale
  systemd.services.tailscale-serve-code-server = {
    description = "Advertise code-server on Tailscale via Caddy";
    after = ["tailscale.service" "code-server.service" "caddy.service"];
    wants = ["tailscale.service" "code-server.service" "caddy.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/code-server http://127.0.0.1:8082/code-server";
      ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/code-server off";
    };
  };
}
