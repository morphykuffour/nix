#
#  These are the different profiles that can be used when building NixOS.
#
#  flake.nix 
#   └─ ./nixos  
#       ├─ ./default.nix *
#       ├─ ./configuration.nix
#       ├─ ./home.nix
#       └─ ./xps17 OR ./vm
#            ├─ ./default.nix
#            └─ ./home.nix 
#

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
          imports = [ (import ./home.nix) ] ++ [ (import ./xps17/home.nix) ];
        };
      }
    ];
  };

  vm = lib.nixosSystem {
    # VM profile
    inherit system;
    specialArgs = { inherit inputs user; };
    modules = [
      ./vm
      ./configuration.nix

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user; };
        home-manager.users.${user} = {
          imports = [ (import ./home.nix) ] ++ [ (import ./vm/home.nix) ];
        };
      }
    ];
  };
}
