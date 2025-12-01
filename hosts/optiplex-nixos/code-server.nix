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
    host = "100.89.107.92"; # Tailscale IP
    port = 8081; # Using 8081 since qBittorrent uses 8080
    auth = "none"; # Tailscale provides authentication
    extraEnvironment = {
      # Prevent code-server from generating a password
      CS_DISABLE_GETTING_STARTED_OVERRIDE = "1";
    };
  };

  # Caddy reverse proxy for HTTPS
  services.caddy = {
    enable = true;
    extraConfig = ''
      optiplex-nixos.tailc585e.ts.net {
        reverse_proxy 100.89.107.92:8081
      }
    '';
  };

  # Allow Caddy to use Tailscale certificates
  systemd.services.caddy = {
    serviceConfig = {
      Environment = "TS_PERMIT_CERT_UID=caddy";
    };
  };

  # Create caddy user and group if they don't exist
  users.users.caddy = {
    isSystemUser = true;
    group = "caddy";
  };
  users.groups.caddy = {};

  # Generate Tailscale certificate for the machine
  systemd.services.tailscale-cert = {
    description = "Generate Tailscale certificate";
    after = ["tailscale.service"];
    wants = ["tailscale.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.services.tailscale.package}/bin/tailscale cert optiplex-nixos.tailc585e.ts.net";
    };
  };

  # Open firewall for code-server (only accessible via Tailscale)
  networking.firewall = {
    allowedTCPPorts = [ 443 ]; # HTTPS via Caddy
  };
}
