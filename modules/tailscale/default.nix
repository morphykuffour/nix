{ config, lib, pkgs, ... }:

let
  latestGo = pkgs.go_1_24; # Fetch the latest Go version
  tailscalePkg = pkgs.tailscale.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ latestGo ];
  });
in
{
  options = {
    services.tailscale.package = lib.mkOption {
      type = lib.types.package;
      default = tailscalePkg;
      description = "The Tailscale package to install.";
    };
  };

  config = {
    environment.systemPackages = [ config.services.tailscale.package ];

    services.tailscale.enable = true;
  };
}
