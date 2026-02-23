{
  config,
  lib,
  pkgs,
  ...
}: let
  mediaUser = "morph";
  mediaUid = builtins.toString config.users.users.morph.uid;
  mediaGid = builtins.toString config.users.groups.users.gid;
  timezone = config.time.timeZone or "Etc/UTC";

  dataRoot = "/var/lib/stremio";
  addonsDataRoot = "${dataRoot}/addons";
  
  # Available Stremio addon community servers (these run externally, no containers needed)
  stremioAddons = {
    # Popular public addons (no containers needed - these are URLs to configure in Stremio)
    torrentio = "https://torrentio.strem.fun/";
    jackett = "https://jackett.elfhosted.com/";
    anime-kitsu = "https://anime-kitsu.strem.fun/";
    opensubtitles = "https://opensubtitles.strem.fun/";
    youtube = "https://youtube.strem.fun/";
    twitch = "https://twitch.strem.fun/";
    iptv-org = "https://iptv-org.strem.fun/";
    watchhub = "https://watchhub.strem.fun/";
    local-files = "https://local-addon.strem.fun/";
    tmdb-addon = "https://tmdb-addon.strem.fun/";
  };

  # Self-hosted addon servers for maximum control
  stremioAddonContainers = {
    # Torrentio self-hosted instance for better control
    torrentio-selfhosted = {
      name = "Torrentio Self-hosted";
      image = "ghcr.io/knightcrawler25/torrentio:latest";
      port = "7000";
      env = {
        PORT = "7000";
        PROWLARR_API_URL = "http://192.168.1.1:9696"; # Your host IP on Tailscale
        JACKETT_API_URL = "http://192.168.1.1:9117";
      };
    };

    # Jackett addon server
    jackett-addon = {
      name = "Jackett Addon";
      image = "sleeyax/stremio-jackett-addon:latest";
      port = "7001";
      env = {
        PORT = "7001";
        JACKETT_URL = "http://192.168.1.1:9117";
      };
    };

    # Local addon for connecting to Jellyfin
    local-addon = {
      name = "Local Addon";
      image = "reddravenn/local-addon:latest";
      port = "7008";
      env = {
        PORT = "7008";
        JELLYFIN_URL = "http://localhost:8096";
      };
    };
  };
in {
  # Configure Docker containers for Stremio server and addons
  virtualisation.oci-containers = {
    backend = "docker";

    containers = {
      # Use Stremio Web (official web interface that runs in browser)
      stremio-web = {
        image = "nginx:alpine";
        autoStart = true;
        ports = ["12470:80"];
        volumes = [
          "${dataRoot}/web:/usr/share/nginx/html:ro"
        ];
        extraOptions = [
          "--restart=unless-stopped"
        ];
      };

      # Stremio streaming server (handles torrent streaming)
      stremio-streaming-server = {
        image = "tsaridas/stremio-docker:latest";
        autoStart = true;
        ports = [
          "8080:8080" # Streaming server
          "11470:11470" # Stremio server API
        ];
        volumes = [
          "${dataRoot}/streaming:/app/server"
          "${config.users.users.morph.home}/Downloads:/downloads"
          "/mnt/nas/media:/media:ro"
        ];
        environment = {
          UID = mediaUid;
          GID = mediaGid;
          TZ = timezone;
        };
        extraOptions = [
          "--restart=unless-stopped"
          "--device=/dev/fuse"
          "--cap-add=SYS_ADMIN"
        ];
      };

    } 

    # Generate self-hosted addon containers
    // (lib.mapAttrs (name: addon: {
      image = addon.image;
      autoStart = true;
      ports = ["${addon.port}:${addon.port}"];
      volumes = [
        "${addonsDataRoot}/${name}:/config"
        "${addonsDataRoot}/shared:/shared:ro"
      ];
      environment = {
        TZ = timezone;
      } // (addon.env or {});
      extraOptions = [
        "--restart=unless-stopped"
        "--network=bridge"
      ];
    }) stremioAddonContainers);
  };

  # Download and setup Stremio Web
  systemd.services.stremio-web-setup = {
    description = "Download and setup Stremio Web";
    wantedBy = ["multi-user.target"];
    before = ["docker-stremio-web.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };
    script = ''
      mkdir -p ${dataRoot}/web
      cd ${dataRoot}/web
      
      # Download latest Stremio Web if not exists
      if [ ! -f "index.html" ]; then
        ${pkgs.wget}/bin/wget -q -O stremio-web.tar.gz \
          https://github.com/Stremio/stremio-web/releases/latest/download/stremio-web.tar.gz
        ${pkgs.gnutar}/bin/tar -xzf stremio-web.tar.gz --strip-components=1
        rm stremio-web.tar.gz
        chown -R ${mediaUser}:users ${dataRoot}/web
      fi
    '';
  };

  # Create systemd tmpfiles for directory structure
  systemd.tmpfiles.rules = [
    "d ${dataRoot} 0750 ${mediaUser} users - -"
    "d ${dataRoot}/web 0755 ${mediaUser} users - -"
    "d ${dataRoot}/streaming 0750 ${mediaUser} users - -"
    "d ${dataRoot}/cache 0750 ${mediaUser} users - -"
    "d ${addonsDataRoot} 0750 ${mediaUser} users - -"
    "d ${addonsDataRoot}/shared 0750 ${mediaUser} users - -"
  ] ++ (lib.flatten (lib.mapAttrsToList (name: addon: [
    "d ${addonsDataRoot}/${name} 0750 ${mediaUser} users - -"
  ]) stremioAddonContainers));

  # Nginx reverse proxy for unified access
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts = {
      # Main Stremio interface accessible via Tailscale
      "stremio.${config.networking.hostName}.ts.net" = {
        locations = {
          "/" = {
            proxyPass = "http://localhost:12470";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
          
          "/streaming/" = {
            proxyPass = "http://localhost:8080/";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };

          # Self-hosted addon endpoints
        } // (lib.mapAttrs' (name: addon: 
          lib.nameValuePair "/addons/${name}/" {
            proxyPass = "http://localhost:${addon.port}/";
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          }
        ) stremioAddonContainers);
      };
    };
  };

  # Firewall configuration
  networking.firewall = {
    allowedTCPPorts = [
      80    # Nginx
      443   # Nginx HTTPS
      8080  # Stremio streaming server
      11470 # Stremio server
      12470 # Stremio web interface
    ] ++ (lib.mapAttrsToList (name: addon: lib.toInt addon.port) stremioAddonContainers);
  };

  # Create addon configuration management script
  environment.systemPackages = with pkgs; [
    (writeScriptBin "stremio-addon-manager" ''
      #!${bash}/bin/bash
      
      ADDON_DATA_ROOT="${addonsDataRoot}"
      SHARED_CONFIG="$ADDON_DATA_ROOT/shared"
      
      case "$1" in
        "setup-debrid")
          echo "Setting up Real-Debrid integration..."
          read -p "Enter Real-Debrid API key: " -s rd_key
          echo "$rd_key" > "$SHARED_CONFIG/real_debrid_key"
          chmod 600 "$SHARED_CONFIG/real_debrid_key"
          echo "Real-Debrid API key saved."
          ;;
        "setup-opensubtitles")
          echo "Setting up OpenSubtitles integration..."
          read -p "Enter OpenSubtitles API key: " -s os_key
          echo "$os_key" > "$SHARED_CONFIG/opensubtitles_key"
          chmod 600 "$SHARED_CONFIG/opensubtitles_key"
          echo "OpenSubtitles API key saved."
          ;;
        "setup-youtube")
          echo "Setting up YouTube integration..."
          read -p "Enter YouTube API key: " -s yt_key
          echo "$yt_key" > "$SHARED_CONFIG/youtube_api_key"
          chmod 600 "$SHARED_CONFIG/youtube_api_key"
          echo "YouTube API key saved."
          ;;
        "list-addons")
          echo "Available Stremio addons:"
          echo ""
          echo "Self-hosted addons:"
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: addon: 
            "echo \"  - ${addon.name} (${name}): http://localhost:${addon.port}\""
          ) stremioAddonContainers)}
          echo ""
          echo "Public addons (configure in Stremio):"
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: url: 
            "echo \"  - ${name}: ${url}\""
          ) stremioAddons)}
          ;;
        "restart-addon")
          if [ -z "$2" ]; then
            echo "Usage: stremio-addon-manager restart-addon <addon-name>"
            exit 1
          fi
          systemctl restart docker-$2.service
          echo "Restarted addon: $2"
          ;;
        *)
          echo "Stremio Addon Manager"
          echo "Usage: $0 {setup-debrid|setup-opensubtitles|setup-youtube|list-addons|restart-addon}"
          echo ""
          echo "Commands:"
          echo "  setup-debrid       - Configure Real-Debrid API key"
          echo "  setup-opensubtitles - Configure OpenSubtitles API key"  
          echo "  setup-youtube      - Configure YouTube API key"
          echo "  list-addons        - Show all available addons"
          echo "  restart-addon      - Restart a specific addon container"
          ;;
      esac
    '')
  ];

  # Integration with existing Tailscale serve
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
      # Add Stremio server
      "${config.services.tailscale.package}/bin/tailscale serve --bg --https=12470 http://127.0.0.1:80; " +
      "${config.services.tailscale.package}/bin/tailscale serve --bg --https=11470 http://127.0.0.1:11470'"
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
      # Remove Stremio serves
      "${config.services.tailscale.package}/bin/tailscale serve --https=12470 off || true; " +
      "${config.services.tailscale.package}/bin/tailscale serve --https=11470 off || true'"
    );

    after = [
      "tailscale.service"
      "nginx.service"
      "docker-stremio-web.service"
      "docker-stremio-streaming-server.service"
    ] ++ (lib.mapAttrsToList (name: addon: "docker-${name}.service") stremioAddonContainers);

    wants = [
      "tailscale.service"
      "nginx.service"
      "docker-stremio-web.service"
      "docker-stremio-streaming-server.service"
    ] ++ (lib.mapAttrsToList (name: addon: "docker-${name}.service") stremioAddonContainers);
  };
}