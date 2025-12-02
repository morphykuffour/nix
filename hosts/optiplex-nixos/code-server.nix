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

  # Serve code-server directly on a separate HTTPS port via Tailscale
  # This avoids subpath issues and WebSocket problems
  systemd.services.tailscale-serve-code-server = {
    description = "Advertise code-server on Tailscale";
    after = ["tailscale.service" "code-server.service"];
    wants = ["tailscale.service" "code-server.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Serve on port 8081 for HTTPS, accessible via :8081
      ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --https=8081 http://127.0.0.1:8081";
      ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=8081 off";
    };
  };
}
