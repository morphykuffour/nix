# https://alberand.com/nixos-wireguard-vpn.html
{ pkgs, ... }: {
  networking.wg-quick.interfaces = let
    server_ip = "43.225.189.131";
  in {
    wg0 = {
      # IP address of this machine in the *tunnel network*
      address = [
        "10.69.52.121/32"
        ":fc00:bbbb:bbbb:bb01::6:3478/128"
      ];

      # To match firewall allowedUDPPorts (without this wg
      # uses random port numbers).
      listenPort = 51820;

      # Path to the private key file.
      privateKeyFile = "/etc/mullvad-vpn.key";

      peers = [{
        publicKey = "CsysTnZ0HvyYRjsKMPx60JIgy777JhD0h9WpbHbV83o=";
        allowedIPs = [ "0.0.0.0/0" ];
        endpoint = "${server_ip}:51820";
        persistentKeepalive = 25;
      }];
    };
  };
}
