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
    host = "127.0.0.1"; # Bind to localhost only, Tailscale serve will handle external access
    port = 8081; # Using 8081 since qBittorrent uses 8080
    auth = "none"; # Tailscale provides authentication
    extraEnvironment = {
      # Prevent code-server from generating a password
      CS_DISABLE_GETTING_STARTED_OVERRIDE = "1";
    };
  };

  # Advertise code-server as a Tailscale service
  systemd.services.tailscale-serve-code-server = {
    description = "Advertise code-server on Tailscale";
    after = ["tailscale.service" "code-server.service"];
    wants = ["tailscale.service" "code-server.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/code-server http://127.0.0.1:8081";
      ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/code-server off";
    };
  };
}
