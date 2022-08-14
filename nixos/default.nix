{ lib, inputs, nixpkgs, home-manager, nur, user, ... }:

let
  system = "x86_64-linux";
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
  lib = nixpkgs.lib;
in
{
  # xps17 profile for nixos
  xps17 = lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs user; };
    modules = [
      nur.nixosModules.nur
      ./xps17
      ./configuration.nix

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user; };
        home-manager.users.${user} = {
          imports = [ ./home.nix ];
        };
      }
    ];
  };
}
