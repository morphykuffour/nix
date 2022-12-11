# TODO: create vscode-server following
# https://tailscale.com/kb/1166/vscode-ipad/
# TODO: create pi-hole following
# https://tailscale.com/kb/1114/pi-hole/
{
  config,
  pkgs,
  lib,
  ...
}: {
  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;

  # if you have a Raspberry Pi 2 or 3, pick this:
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # A bunch of boot parameters needed for optimal runtime on RPi 3b+
  boot.kernelParams = ["cma=256M"];
  boot.loader.raspberryPi.enable = true;
  boot.loader.raspberryPi.version = 3;
  boot.loader.raspberryPi.uboot.enable = true;
  boot.loader.raspberryPi.firmwareConfig = ''
    gpu_mem=256
  '';

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];

  # File systems configuration for using the installer's partition layout
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  # Preserve space by sacrificing documentation and history
  documentation.nixos.enable = true;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 30d";
  boot.cleanTmpDir = true;

  # Configure basic SSH access
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  # Use 1GB of additional swap memory in order to not run out of memory
  # when installing lots of things while running other things at the same time.
  swapDevices = [
    {
      device = "/swapfile";
      size = 1024;
    }
  ];
  system.stateVersion = config.system.nixos.release;

  # tailscale
  services.tailscale.enable = true;

  age.identityPaths = [
    "/home/nixos/.ssh/id_ed25519"
  ];
  age.secrets.ts-xps17-nixos.file = ../../secrets/ts-rpi3b-nixos.age;

  # create a oneshot job to authenticate to Tailscale
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = ["network-pre.target" "tailscale.service"];
    wants = ["network-pre.target" "tailscale.service"];
    wantedBy = ["multi-user.target"];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up --authkey=$(cat ${config.age.secrets.ts-rpi3b-nixos.path})
    '';
  };

  networking.firewall = {
    # warning: Strict reverse path filtering breaks Tailscale
    # exit node use and some subnet routing setups.
    checkReversePath = "loose";
    # enable the firewall
    enable = true;

    # always allow traffic from your Tailscale network
    trustedInterfaces = ["tailscale0"];

    # allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [config.services.tailscale.port];

    # allow you to SSH in over the public internet
    allowedTCPPorts = [22];
  };
}
