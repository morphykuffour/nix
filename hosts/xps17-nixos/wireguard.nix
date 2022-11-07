#
# wireguard client for protonvpn wireguard server
#
# nmcli connection import type wireguard file protonvpn_wireguard-US-FREE_2.conf
# TODO: add wireguard client for protonvpn
# https://nixos.wiki/wiki/WireGuard#Setting_up_WireGuard_server.2Fclient_with_wg-quick_and_dnsmasq
# https://account.protonvpn.com/downloads#wireguard-configuration
{
  config,
  pkgs,
  lib,
  ...
}: {
  networking = {
    wireguard = {
      enable = true;
    };
    firewall = {
      allowedUDPPorts = [51820]; # Clients and peers can use the same port, see listenport
      # if packets are still dropped, they will show up in dmesg
      logReversePathDrops = true;
      # wireguard trips rpfilter up
      extraCommands = ''
        ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN
        ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN
      '';
      extraStopCommands = ''
        ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN || true
        ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN || true
      '';
    };
  };
}
