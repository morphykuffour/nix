# https://alberand.com/nixos-wireguard-vpn.html
{
  pkgs,
  agenix,
  config,
  ...
}: let
  server_ip = "43.225.189.131";
in {
  age.identityPaths = [
    "/home/morph/.ssh/id_ed25519"
  ];

  age.secrets.wireguard-xps17-nixos.file = ../../secrets/wireguard-xps17-nixos.age;

  networking.wg-quick.interfaces.wg0 = {
    # IP address of this machine in the *tunnel network*
    address = [
      "10.69.46.62/32"
      "fc00:bbbb:bbbb:bb01::6:2e3d/128"
    ];

    # To match firewall allowedUDPPorts (without this wg
    # uses random port numbers).
    listenPort = 51820;

    # Path to the private key file.
    privateKeyFile = config.age.secrets.wireguard-xps17-nixos.path;

    peers = [
      {
        publicKey = "CsysTnZ0HvyYRjsKMPx60JIgy777JhD0h9WpbHbV83o=";
        allowedIPs = ["0.0.0.0/0"];
        endpoint = "${server_ip}:51820";
        persistentKeepalive = 25;
      }
    ];
    postUp = ''
      # Mark packets on the wg0 interface
      wg set wg0 fwmark 51820

      # Forbid anything else which doesn't go through wireguard VPN on
      # ipV4 and ipV6
      ${pkgs.iptables}/bin/iptables -A OUTPUT \
        ! -d 192.168.0.0/16 \
        ! -o wg0 \
        -m mark ! --mark $(wg show wg0 fwmark) \
        -m addrtype ! --dst-type LOCAL \
        -j REJECT
      ${pkgs.iptables}/bin/ip6tables -A OUTPUT \
        ! -o wg0 \
        -m mark ! --mark $(wg show wg0 fwmark) \
        -m addrtype ! --dst-type LOCAL \
        -j REJECT
    '';
    postDown = ''
      ${pkgs.iptables}/bin/iptables -D OUTPUT \
        ! -o wg0 \
        -m mark ! --mark $(wg show wg0 fwmark) \
        -m addrtype ! --dst-type LOCAL \
        -j REJECT
      ${pkgs.iptables}/bin/ip6tables -D OUTPUT \
        ! -o wg0 -m mark \
        ! --mark $(wg show wg0 fwmark) \
        -m addrtype ! --dst-type LOCAL \
        -j REJECT
    '';
  };
}
