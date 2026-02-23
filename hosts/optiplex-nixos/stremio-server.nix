{
  config,
  lib,
  pkgs,
  ...
}: let
  mediaUser = "morph";
  mediaUid = builtins.toString config.users.users.morph.uid;
  mediaGid = builtins.toString config.users.groups.users.gid;
  dataRoot = "/var/lib/stremio";
in {
  # Real Stremio streaming server setup
  virtualisation.oci-containers = {
    backend = "docker";
    
    containers = {
      # Stremio Streaming Server - handles torrent streaming
      stremio-server = {
        image = "tsaridas/stremio-docker:latest";
        autoStart = true;
        ports = [
          "11470:11470" # Stremio server API
          "12470:8080"  # Web interface (mapped to port 12470)
        ];
        volumes = [
          "${dataRoot}/server:/app/server"
          "${dataRoot}/cache:/app/cache" 
          "/tmp:/tmp"
        ];
        environment = {
          PUID = mediaUid;
          PGID = mediaGid;
          TZ = config.time.timeZone or "America/New_York";
          # Enable CORS for web access
          STREAMING_SERVER_URL = "http://localhost:11470";
          NO_CORS = "1";
        };
        extraOptions = [
          "--restart=unless-stopped"
          "--security-opt=apparmor:unconfined"
          "--cap-add=SYS_ADMIN"
          "--device=/dev/fuse"
        ];
      };
    };
  };

  # Create systemd tmpfiles for directory structure
  systemd.tmpfiles.rules = [
    "d ${dataRoot} 0755 ${mediaUser} users - -"
    "d ${dataRoot}/server 0755 ${mediaUser} users - -"
    "d ${dataRoot}/cache 0755 ${mediaUser} users - -"
  ];

  # Nginx reverse proxy configuration
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts = {
      "default" = {
        listen = [ { addr = "0.0.0.0"; port = 8080; } ];
        locations = {
          "/" = {
            proxyPass = "http://localhost:12470";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              
              # CORS headers for Stremio
              add_header Access-Control-Allow-Origin "*" always;
              add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
              add_header Access-Control-Allow-Headers "Origin, Content-Type, Accept, Authorization" always;
              
              if ($request_method = OPTIONS) {
                return 204;
              }
            '';
          };
          
          # Streaming server API
          "/api/" = {
            proxyPass = "http://localhost:11470/";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              
              # CORS headers
              add_header Access-Control-Allow-Origin "*" always;
              add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
              add_header Access-Control-Allow-Headers "Origin, Content-Type, Accept, Authorization" always;
              
              if ($request_method = OPTIONS) {
                return 204;
              }
            '';
          };
        };
      };
    };
  };

  # Firewall configuration
  networking.firewall = {
    allowedTCPPorts = [
      8080  # Nginx proxy to Stremio
      11470 # Stremio server API
      12470 # Stremio web interface (Docker internal)
    ];
  };

  # Create Stremio management script
  environment.systemPackages = with pkgs; [
    (writeScriptBin "stremio-server-manager" ''
      #!${bash}/bin/bash
      
      case "$1" in
        "status")
          echo "Stremio Server Status:"
          systemctl status docker-stremio-server.service | grep -E "(Active|Main PID)"
          echo ""
          docker ps --filter "name=stremio" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
          echo ""
          echo "Access URLs:"
          echo "  Local: http://localhost:8080"
          echo "  Tailscale: https://$(${config.services.tailscale.package}/bin/tailscale ip -4):8080"
          ;;
        "logs")
          echo "Stremio Server Logs:"
          docker logs stremio-server --tail 50
          ;;
        "restart")
          echo "Restarting Stremio server..."
          systemctl restart docker-stremio-server.service
          sleep 5
          systemctl status docker-stremio-server.service
          ;;
        "shell")
          echo "Opening shell in Stremio container..."
          docker exec -it stremio-server /bin/sh
          ;;
        *)
          echo "Stremio Server Manager"
          echo "Usage: $0 {status|logs|restart|shell}"
          echo ""
          echo "Commands:"
          echo "  status   - Show service status and access URLs"
          echo "  logs     - Show container logs"
          echo "  restart  - Restart the Stremio server"
          echo "  shell    - Open shell in container"
          ;;
      esac
    '')
  ];

  # Update Tailscale serve configuration
  systemd.services.tailscale-serve-config = {
    serviceConfig.ExecStart = lib.mkForce (
      "${pkgs.bash}/bin/bash -euc '" +
      # Existing serves from tailscale.nix
      "${config.services.tailscale.package}/bin/tailscale serve --bg --https=445 http://127.0.0.1:3030; " +
      "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/search http://127.0.0.1:8888; " +
      "${config.services.tailscale.package}/bin/tailscale serve --bg --https=8443 http://127.0.0.1:8888; " +
      "${config.services.tailscale.package}/bin/tailscale serve --bg --https=444 http://127.0.0.1:3000; " +
      "${config.services.tailscale.package}/bin/tailscale serve --bg --https=8081 http://127.0.0.1:8081; " +
      "${config.services.tailscale.package}/bin/tailscale serve --bg --https=24153 http://127.0.0.1:24153; " +
      "${config.services.tailscale.package}/bin/tailscale serve --bg --https=6060 http://127.0.0.1:6060; " +
      # Add Stremio server on port 8080 (the nginx proxy)
      "${config.services.tailscale.package}/bin/tailscale serve --bg --https=8080 http://127.0.0.1:8080'"
    );
    
    serviceConfig.ExecStop = lib.mkForce (
      "${pkgs.bash}/bin/bash -euc '" +
      "${config.services.tailscale.package}/bin/tailscale serve --https=445 off || true; " +
      "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/search off || true; " +
      "${config.services.tailscale.package}/bin/tailscale serve --https=8443 off || true; " +
      "${config.services.tailscale.package}/bin/tailscale serve --https=444 off || true; " +
      "${config.services.tailscale.package}/bin/tailscale serve --https=8081 off || true; " +
      "${config.services.tailscale.package}/bin/tailscale serve --https=24153 off || true; " +
      "${config.services.tailscale.package}/bin/tailscale serve --https=6060 off || true; " +
      # Remove Stremio serve
      "${config.services.tailscale.package}/bin/tailscale serve --https=8080 off || true'"
    );

    after = [
      "tailscale.service"
      "nginx.service" 
      "docker-stremio-server.service"
    ];

    wants = [
      "tailscale.service"
      "nginx.service"
      "docker-stremio-server.service"
    ];
  };
}