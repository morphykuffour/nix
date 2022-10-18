{
  config,
  pkgs,
  lib,
  ...
}: let
  path = ".config/spotifyd";
  file = "spotifyd.conf";
  settings = {
    global = {
      username = "morpkuff";
      password_cmd = "pass spotify";
      backend = "alsa";
      device_name = "xps17";
      device_type = "computer";
      device = "alsa_audio_device";
      control = "alsa_audio_device";
      bitrate = 320;
      # volume_controller = "alsa"; # use softvol for macOS
      # volume_normalisation = true;
      # normalisation_pregain = -10;
      # zeroconf_port = 8888;
      # proxy = "http://localhost:8888";
      # use_mpris = true;
      # mixer = "PCM";
    };
  };

  toml = pkgs.formats.toml {};
  config = toml.generate file settings;
in {
  home.file."${path}/${file}".source = config;
}
# { config, pkgs, lib, ... }:
# {
#   services.spotifyd = {
#     enable = true;
#     config = ''
#       [global]
#       username = morpkuff
#       password = pass spotify
#       backend = pipewire
#       device_name = xps17
#       bitrate = 320
#       volume_normalisation = true
#       normalisation_pregain = -10
#       device_type = stb
#       zeroconf_port = 8888
#       proxy = "http://localhost:8888"
#       use_mpris = true
#       mixer = "PCM"
#       volume_controller = "alsa"  # use softvol for macOS
#     '';
#   };
#   # HACK: the provided service uses a dynamic user which can not authenticate to the pulse daemon
#   # This is mitigated by using a static user
#   users.users.spotifyd = {
#     group = "audio";
#     extraGroups = [ "audio" ];
#     description = "spotifyd daemon user";
#     home = "/var/lib/spotifyd";
#   };
#   systemd.services.spotifyd = {
#     serviceConfig.User = "spotifyd";
#     serviceConfig.DynamicUser = lib.mkForce false;
#     serviceConfig.SupplementaryGroups = lib.mkForce [ ];
#   };
#   # End of hack...
#   # firewall.rules = dag: with dag; {
#   #   inet.filter.input = {
#   #     spotify-tcp = between [ "established" ] [ "drop" ] ''
#   #       ip saddr 172.23.200.0/24
#   #       tcp dport 4444
#   #       accept
#   #     '';
#   #     spotify-udp = between [ "established" ] [ "drop" ] ''
#   #       ip saddr 172.23.200.0/24
#   #       udp dport 5353
#   #       accept
#   #     '';
#   #   };
#   # };
# }

