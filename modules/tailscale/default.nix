{ config, lib, pkgs, ... }:

{
  config = {
    environment.systemPackages = [ config.services.tailscale.package ];

    services.tailscale = {
      enable = true;
      package = lib.mkForce pkgs.tailscale;
    };
  };
}
