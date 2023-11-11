{
  pkgs,
  config,
  ...
}: {

  environment.systemPackages = [pkgs.mullvad-vpn pkgs.mullvad];
  services.mullvad-vpn = {
    enable = true;
  };

  systemd.services."mullvad-daemon".postStart = let
    mullvad = config.services.mullvad-vpn.package;
  in ''
    while ! ${mullvad}/bin/mullvad status >/dev/null; do sleep 1; done
    ${mullvad}/bin/mullvad auto-connect set on
    ${mullvad}/bin/mullvad tunnel ipv6 set on
    ${mullvad}/bin/mullvad set default \
        --block-ads --block-trackers --block-malware
  '';
}
