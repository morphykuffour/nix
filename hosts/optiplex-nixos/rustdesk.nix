{ config, pkgs, ... }:

let
  # RustDesk server ports
  hbbs_port = 21115;      # TCP - ID/Rendezvous server
  hbbs_port_udp = 21116;  # UDP - ID/Rendezvous server
  hbbs_port_web = 21114;  # TCP - Web console (admin)
  hbbr_port = 21117;      # TCP - Relay server
  hbbr_port_ws = 21119;   # TCP - Relay server WebSocket

  # Data directory for RustDesk
  rustdesk_data = "/var/lib/rustdesk";
in
{
  # Create data directory
  systemd.tmpfiles.rules = [
    "d ${rustdesk_data} 0750 rustdesk rustdesk - -"
  ];

  # Create rustdesk user
  users.users.rustdesk = {
    isSystemUser = true;
    group = "rustdesk";
    home = rustdesk_data;
    createHome = true;
  };
  users.groups.rustdesk = {};

  # RustDesk hbbs (ID/Rendezvous server)
  systemd.services.rustdesk-hbbs = {
    description = "RustDesk ID/Rendezvous Server (hbbs)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "rustdesk";
      Group = "rustdesk";
      WorkingDirectory = rustdesk_data;
      ExecStart = ''
        ${pkgs.rustdesk-server}/bin/hbbs \
          -p ${toString hbbs_port} \
          -k _ \
          -r 127.0.0.1:${toString hbbr_port}
      '';
      Restart = "on-failure";
      RestartSec = "5s";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ rustdesk_data ];

      # Network optimizations for high throughput
      LimitNOFILE = 1000000;
      LimitNPROC = 512;
    };
  };

  # RustDesk hbbr (Relay server)
  systemd.services.rustdesk-hbbr = {
    description = "RustDesk Relay Server (hbbr)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "rustdesk";
      Group = "rustdesk";
      WorkingDirectory = rustdesk_data;
      ExecStart = ''
        ${pkgs.rustdesk-server}/bin/hbbr \
          -p ${toString hbbr_port} \
          -k _
      '';
      Restart = "on-failure";
      RestartSec = "5s";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ rustdesk_data ];

      # Network optimizations for high throughput
      LimitNOFILE = 1000000;
      LimitNPROC = 512;
    };
  };

  # Advertise RustDesk web console via Tailscale
  systemd.services.tailscale-serve-rustdesk = {
    description = "Advertise RustDesk Web Console on Tailscale";
    after = [ "tailscale.service" "rustdesk-hbbs.service" ];
    wants = [ "tailscale.service" "rustdesk-hbbs.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 --set-path=/rustdesk http://127.0.0.1:${toString hbbs_port_web}";
      ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=443 --set-path=/rustdesk off";
    };
  };

  # High throughput kernel optimizations
  boot.kernel.sysctl = {
    # TCP BBR congestion control for better throughput
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";

    # Increase network buffers for high throughput
    "net.core.rmem_max" = 134217728;          # 128 MB
    "net.core.wmem_max" = 134217728;          # 128 MB
    "net.core.rmem_default" = 16777216;       # 16 MB
    "net.core.wmem_default" = 16777216;       # 16 MB
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";

    # Increase max connections
    "net.core.somaxconn" = 65535;
    "net.core.netdev_max_backlog" = 65536;
    "net.ipv4.tcp_max_syn_backlog" = 65536;

    # TCP optimizations
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_tw_reuse" = 1;

    # Reduce TCP keepalive time
    "net.ipv4.tcp_keepalive_time" = 600;
    "net.ipv4.tcp_keepalive_intvl" = 60;
    "net.ipv4.tcp_keepalive_probes" = 3;
  };

  # Firewall configuration
  networking.firewall = {
    # RustDesk ports - allow both local network and Tailscale
    allowedTCPPorts = [
      hbbs_port       # 21115 - ID/Rendezvous
      hbbr_port       # 21117 - Relay
      hbbr_port_ws    # 21119 - Relay WebSocket
      hbbs_port_web   # 21114 - Web console (optional, mainly for Tailscale)
    ];
    allowedUDPPorts = [
      hbbs_port_udp   # 21116 - ID/Rendezvous UDP
    ];

    # Allow these ports on Tailscale interface
    interfaces.tailscale0 = {
      allowedTCPPorts = [ hbbs_port hbbr_port hbbr_port_ws hbbs_port_web ];
      allowedUDPPorts = [ hbbs_port_udp ];
    };
  };

  # Add rustdesk-server package to system
  environment.systemPackages = with pkgs; [
    rustdesk-server
  ];
}
