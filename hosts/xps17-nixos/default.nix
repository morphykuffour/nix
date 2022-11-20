{
  config,
  pkgs,
  user,
  ...
}: {
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    ./zfs.nix
  ];
}
