# Wake-on-LAN configuration for optiplex-nixos
# Enables remote wake from sleep/shutdown via magic packet
{
  config,
  pkgs,
  lib,
  ...
}: let
  # Primary network interface
  interface = "enp0s31f6";
in {
  # Enable Wake-on-LAN for the primary network interface
  networking.interfaces.${interface}.wakeOnLan.enable = true;

  # Install ethtool for WoL management
  environment.systemPackages = with pkgs; [
    ethtool
  ];

  # Systemd service to ensure WoL is enabled on boot
  # This is a backup in case the networking.interfaces option doesn't work
  systemd.services.wakeonlan = {
    description = "Enable Wake-on-LAN on ${interface}";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.ethtool}/bin/ethtool -s ${interface} wol g";
    };
  };

  # Helper script to check WoL status
  environment.etc."profile.d/wol-helper.sh".text = ''
    # Wake-on-LAN helpers
    alias wol-status='sudo ethtool ${interface} | grep Wake-on'
    alias wol-enable='sudo ethtool -s ${interface} wol g'
    alias wol-info='echo "Interface: ${interface}" && ip link show ${interface} | grep "link/ether" && sudo ethtool ${interface} | grep -E "(Wake-on|Link detected)"'

    # Show MAC address for WoL commands
    alias wol-mac='ip link show ${interface} | grep "link/ether" | awk "{print \$2}"'
  '';
}
