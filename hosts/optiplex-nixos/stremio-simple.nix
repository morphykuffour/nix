{
  config,
  lib,
  pkgs,
  ...
}: let
  mediaUser = "morph";
  dataRoot = "/var/lib/stremio";
in {
  # Simple Stremio Web service using built-in web server
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts = {
      # Main Stremio interface accessible via Tailscale
      "default" = {
        listen = [ { addr = "0.0.0.0"; port = 12470; } ];
        locations = {
          "/" = {
            root = "${dataRoot}/web";
            index = "index.html";
            tryFiles = "$uri $uri/ /index.html";
            extraConfig = ''
              add_header Cross-Origin-Embedder-Policy require-corp;
              add_header Cross-Origin-Opener-Policy same-origin;
              
              # Allow CORS for Stremio addons
              add_header Access-Control-Allow-Origin *;
              add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS';
              add_header Access-Control-Allow-Headers 'Origin, Content-Type, Accept, Authorization';
              
              if ($request_method = OPTIONS) {
                return 204;
              }
            '';
          };
        };
      };
    };
  };

  # Create systemd tmpfiles for directory structure
  systemd.tmpfiles.rules = [
    "d ${dataRoot} 0750 ${mediaUser} users - -"
    "d ${dataRoot}/web 0755 ${mediaUser} users - -"
  ];

  # Download and setup Stremio Web
  systemd.services.stremio-web-setup = {
    description = "Download and setup Stremio Web";
    wantedBy = ["multi-user.target"];
    before = ["nginx.service"];
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
        echo "Downloading Stremio Web..."
        
        # Use the public web version of Stremio
        ${pkgs.wget}/bin/wget -q -O - https://app.strem.io/ > index.html || {
          echo "Failed to download from app.strem.io, creating redirect page..."
          cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Stremio Web</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { 
            font-family: Arial, sans-serif; 
            text-align: center; 
            background: #1a1a1a; 
            color: white; 
            margin: 0; 
            padding: 50px;
        }
        .container { 
            max-width: 600px; 
            margin: 0 auto;
        }
        .logo {
            font-size: 2em;
            margin-bottom: 30px;
            color: #7b5cf0;
        }
        .info {
            margin: 20px 0;
            line-height: 1.6;
        }
        .link {
            display: inline-block;
            background: #7b5cf0;
            color: white;
            text-decoration: none;
            padding: 15px 30px;
            border-radius: 8px;
            margin: 10px;
            font-weight: bold;
        }
        .link:hover {
            background: #6a4ed6;
        }
        .addon-list {
            text-align: left;
            background: #2a2a2a;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .addon-item {
            margin: 10px 0;
            padding: 10px;
            background: #333;
            border-radius: 4px;
        }
        .addon-url {
            font-family: monospace;
            color: #7b5cf0;
            word-break: break-all;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🎬 Stremio Streaming Server</div>
        
        <div class="info">
            <p>Your Stremio server is running! To start streaming:</p>
            
            <a href="https://app.strem.io/" target="_blank" class="link">Open Stremio Web App</a>
            
            <p>Or download the official Stremio app for your device and connect to this server.</p>
        </div>

        <div class="addon-list">
            <h3>📦 Recommended Addons</h3>
            <p>Add these to your Stremio app for the best experience:</p>
            
            <div class="addon-item">
                <strong>🎬 Torrentio</strong><br>
                <span class="addon-url">https://torrentio.strem.fun</span><br>
                <small>Best torrent streaming addon with Real-Debrid support</small>
            </div>
            
            <div class="addon-item">
                <strong>📝 OpenSubtitles</strong><br>
                <span class="addon-url">https://opensubtitles.strem.fun</span><br>
                <small>Automatic subtitles for movies and TV shows</small>
            </div>
            
            <div class="addon-item">
                <strong>🎥 YouTube</strong><br>
                <span class="addon-url">https://youtube.strem.fun</span><br>
                <small>YouTube content integration</small>
            </div>
            
            <div class="addon-item">
                <strong>📺 IPTV</strong><br>
                <span class="addon-url">https://iptv-org.strem.fun</span><br>
                <small>Live TV channels</small>
            </div>
            
            <div class="addon-item">
                <strong>🎌 Anime Kitsu</strong><br>
                <span class="addon-url">https://anime-kitsu.strem.fun</span><br>
                <small>Anime content from Kitsu database</small>
            </div>
        </div>
        
        <div class="info">
            <p><strong>🔗 Access from anywhere on your Tailscale network!</strong></p>
            <p>Your media server is integrated with Jellyfin, Radarr, Sonarr, and more.</p>
        </div>
    </div>
</body>
</html>
EOF
        }
        
        chown -R ${mediaUser}:users ${dataRoot}/web
        echo "Stremio Web setup complete"
      else
        echo "Stremio Web already exists"
      fi
    '';
  };

  # Firewall configuration
  networking.firewall = {
    allowedTCPPorts = [
      12470 # Stremio web interface
    ];
  };

  # Create addon management script
  environment.systemPackages = with pkgs; [
    (writeScriptBin "stremio-manager" ''
      #!${bash}/bin/bash
      
      case "$1" in
        "status")
          echo "Stremio Server Status:"
          systemctl status nginx.service | grep -E "(Active|Main PID)"
          systemctl status stremio-web-setup.service | grep -E "(Active|Main PID)"
          echo ""
          echo "Access URL: http://$(${tailscale}/bin/tailscale ip -4):12470"
          ;;
        "restart")
          echo "Restarting Stremio services..."
          systemctl restart stremio-web-setup.service
          systemctl restart nginx.service
          echo "Services restarted"
          ;;
        "logs")
          echo "=== Nginx logs ==="
          journalctl -u nginx.service --no-pager -n 20
          echo ""
          echo "=== Setup logs ==="
          journalctl -u stremio-web-setup.service --no-pager -n 20
          ;;
        "addons")
          echo "🔌 Recommended Stremio Addons:"
          echo ""
          echo "🎬 Torrentio (Premium torrents):"
          echo "   https://torrentio.strem.fun"
          echo ""
          echo "📝 OpenSubtitles (Subtitles):"
          echo "   https://opensubtitles.strem.fun"
          echo ""
          echo "🎥 YouTube (YouTube content):"
          echo "   https://youtube.strem.fun"
          echo ""
          echo "📺 IPTV (Live TV):"
          echo "   https://iptv-org.strem.fun"
          echo ""
          echo "🎌 Anime Kitsu (Anime):"
          echo "   https://anime-kitsu.strem.fun"
          echo ""
          echo "💎 TMDB (Movie Database):"
          echo "   https://tmdb-addon.strem.fun"
          echo ""
          echo "To add an addon:"
          echo "1. Open Stremio app or web interface"
          echo "2. Go to Addons section"
          echo "3. Click + and paste the addon URL"
          ;;
        *)
          echo "Stremio Manager"
          echo "Usage: $0 {status|restart|logs|addons}"
          echo ""
          echo "Commands:"
          echo "  status   - Show service status and access URL"
          echo "  restart  - Restart Stremio services"
          echo "  logs     - Show service logs"
          echo "  addons   - List recommended addons"
          ;;
      esac
    '')
  ];

  # Update existing Tailscale serve configuration
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
      "${config.services.tailscale.package}/bin/tailscale serve --bg --https=12470 http://127.0.0.1:12470'"
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
      "${config.services.tailscale.package}/bin/tailscale serve --https=12470 off || true'"
    );

    after = [
      "tailscale.service"
      "nginx.service" 
      "stremio-web-setup.service"
    ];

    wants = [
      "tailscale.service"
      "nginx.service"
      "stremio-web-setup.service"
    ];
  };
}