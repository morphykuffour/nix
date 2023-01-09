{
  config,
  pkgs,
  user,
  ...
}: {
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    # TODO: fix backup with borg
    ./backup.nix
    ./tailscale.nix
    # TODO: move drive to zfs
    # ./zfs.nix
    # ../../modules/emacs
  ];
}
