# https://github.com/rayandrew/nix-config/blob/7efd7fd90575c7f64cc96faf5eda79727b6b5e9d/nixos/vpn.nix
# https://haseebmajid.dev/posts/2023-06-20-til-how-to-declaratively-setup-mullvad-with-nixos/
{
  pkgs,
  config,
  agenix,
  ...
}: let
  mullvad = "${config.services.mullvad-vpn.package}/bin/mullvad";
in {
  age.identityPaths = [
    "/home/morph/.ssh/id_ed25519"
  ];

  age.secrets.mullvadvpn-xps17-nixos.file = ../../secrets/mullvadvpn-xps17-nixos.age;

  # environment.systemPackages = [pkgs.mullvad-vpn pkgs.mullvad];
  services.mullvad-vpn = {
    enable = true;
  };

  # systemd service
  systemd.services."mullvad-daemon".preStart = ''
  '';

  systemd.services."mullvad-daemon".postStart = ''
    while ! ${mullvad} status >/dev/null; do sleep 1; done
    ID=`head -n1 ${config.age.secrets.mullvadvpn-xps17-nixos.path}`
    ${mullvad} account login "$ID"
    ${mullvad} auto-connect set on
    ${mullvad} relay set location us
    ${mullvad} tunnel ipv6 set on
    ${mullvad} dns set default \
       --block-ads --block-malware --block-trackers

    # ── add Shadowsocks bridge setup here ──
    ${mullvad} bridge set location any
    ${mullvad} bridge set state on
  '';
}

# system-wide proxy at 127.0.0.1:1080
