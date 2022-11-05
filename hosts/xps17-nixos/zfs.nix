# https://nixos.wiki/wiki/ZFS
{
  config,
  pkgs,
  ...
}: {
  # /dev/nvme0n1 -> primary disk for ext4 fs
  # /dev/nvme1n1 -> secondary disk for zfs fs
  boot.supportedFilesystems = ["zfs"];
  networking.hostId = "319155cd";
}
