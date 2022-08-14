{ config, pkgs, user, ... }:

{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    ./picom.nix
    ./zfs.nix
  ];
}
