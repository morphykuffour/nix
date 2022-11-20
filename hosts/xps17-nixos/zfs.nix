# https://nixos.wiki/wiki/ZFS
{
  config,
  pkgs,
  ...
}: {
  # /dev/nvme0n1 -> primary disk for ext4 fs => NixOs
  # /dev/nvme1n1 -> secondary disk for zfs fs => RedNixOS and Arch Linux
  boot.supportedFilesystems = ["zfs"];
  networking.hostId = "319155cd";
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
}
