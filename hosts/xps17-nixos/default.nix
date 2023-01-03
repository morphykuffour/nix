{
  config,
  pkgs,
  user,
  ...
}: {
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    ./backup.nix
    ./tailscale.nix
    # TODO: move drive to zfs
    # ./zfs.nix
  ];
}
