{ config, lib, ... }:

let
  mediaUser = "morph";
  mediaUid = builtins.toString config.users.users.morph.uid;
  mediaGid = builtins.toString config.users.groups.users.gid;
  timezone = config.time.timeZone or "Etc/UTC";

  dataRoot = "/var/lib/media-stack";
  mediaRoot = "/mnt/nas";
  downloadsRoot = "${mediaRoot}/downloads";
  gluetunEnvFile = "${dataRoot}/gluetun/gluetun.env";
in {
  virtualisation.oci-containers = {
    backend = "docker";

    containers = {
      gluetun = {
        image = "qmcgaw/gluetun";
        autoStart = true;
        volumes = [
          "${dataRoot}/gluetun:/gluetun"
        ];
        environment = {
          VPN_TYPE = "openvpn";
          VPN_SERVICE_PROVIDER = "protonvpn";
          VPN_PORT_FORWARDING = "on";
          SERVER_COUNTRIES = "United States";
          TZ = timezone;
        };
        environmentFiles = [gluetunEnvFile];
        ports = [
          "8701:8701"
          "6881:6881"
          "6881:6881/udp"
          "7878:7878"
          "8989:8989"
          "8686:8686"
          "6767:6767"
          "9696:9696"
          "8191:8191"
        ];
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--device=/dev/net/tun"
        ];
      };

      qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent";
        autoStart = true;
        dependsOn = ["gluetun"];
        volumes = [
          "${dataRoot}/qbittorrent:/config"
          "${mediaRoot}:/data"
          "${downloadsRoot}:/downloads"
        ];
        environment = {
          PUID = mediaUid;
          PGID = mediaGid;
          TZ = timezone;
          WEBUI_PORT = "8701";
          WEBUI_ADDRESS = "0.0.0.0";
          WEBUI_EXTERNAL_ACCESS = "true";
        };
        extraOptions = ["--network=container:gluetun"];
      };

      radarr = {
        image = "lscr.io/linuxserver/radarr";
        autoStart = true;
        dependsOn = ["gluetun"];
        volumes = [
          "${dataRoot}/radarr:/config"
          "${mediaRoot}:/data"
        ];
        environment = {
          PUID = mediaUid;
          PGID = mediaGid;
          TZ = timezone;
        };
        extraOptions = ["--network=container:gluetun"];
      };

      sonarr = {
        image = "lscr.io/linuxserver/sonarr";
        autoStart = true;
        dependsOn = ["gluetun"];
        volumes = [
          "${dataRoot}/sonarr:/config"
          "${mediaRoot}:/data"
        ];
        environment = {
          PUID = mediaUid;
          PGID = mediaGid;
          TZ = timezone;
        };
        extraOptions = ["--network=container:gluetun"];
      };

      lidarr = {
        image = "lscr.io/linuxserver/lidarr:latest";
        autoStart = true;
        dependsOn = ["gluetun"];
        volumes = [
          "${dataRoot}/lidarr:/config"
          "${mediaRoot}:/data"
        ];
        environment = {
          PUID = mediaUid;
          PGID = mediaGid;
          TZ = timezone;
        };
        extraOptions = ["--network=container:gluetun"];
      };

      bazarr = {
        image = "lscr.io/linuxserver/bazarr";
        autoStart = true;
        dependsOn = ["gluetun"];
        volumes = [
          "${dataRoot}/bazarr:/config"
          "${mediaRoot}:/data"
        ];
        environment = {
          PUID = mediaUid;
          PGID = mediaGid;
          TZ = timezone;
        };
        extraOptions = ["--network=container:gluetun"];
      };

      prowlarr = {
        image = "lscr.io/linuxserver/prowlarr";
        autoStart = true;
        dependsOn = ["gluetun"];
        volumes = [
          "${dataRoot}/prowlarr:/config"
        ];
        environment = {
          PUID = mediaUid;
          PGID = mediaGid;
          TZ = timezone;
        };
        extraOptions = ["--network=container:gluetun"];
      };

      flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        autoStart = true;
        dependsOn = ["gluetun"];
        environment = {
          TZ = timezone;
        };
        extraOptions = ["--network=container:gluetun"];
      };

      jellyseerr = {
        image = "fallenbagel/jellyseerr:latest";
        autoStart = true;
        volumes = ["${dataRoot}/jellyseerr:/app/config"];
        environment = {
          TZ = timezone;
          LOG_LEVEL = "info";
        };
        ports = ["5055:5055"];
        dependsOn = ["gluetun" "sonarr" "radarr"];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataRoot} 0750 ${mediaUser} users - -"
    "d ${dataRoot}/gluetun 0750 ${mediaUser} users - -"
    "f ${gluetunEnvFile} 0600 ${mediaUser} users - -"
    "d ${dataRoot}/qbittorrent 0750 ${mediaUser} users - -"
    "d ${dataRoot}/radarr 0750 ${mediaUser} users - -"
    "d ${dataRoot}/sonarr 0750 ${mediaUser} users - -"
    "d ${dataRoot}/lidarr 0750 ${mediaUser} users - -"
    "d ${dataRoot}/bazarr 0750 ${mediaUser} users - -"
    "d ${dataRoot}/prowlarr 0750 ${mediaUser} users - -"
    "d ${dataRoot}/jellyseerr 0750 ${mediaUser} users - -"
    "d ${downloadsRoot} 0775 ${mediaUser} users - -"
    "d ${downloadsRoot}/movies 0775 ${mediaUser} users - -"
    "d ${downloadsRoot}/tv 0775 ${mediaUser} users - -"
    "d ${downloadsRoot}/music 0775 ${mediaUser} users - -"
    "d ${downloadsRoot}/audiobooks 0775 ${mediaUser} users - -"
  ];
}
