{
  description = "My Personal NixOS and Darwin System Flake Configuration";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    nur = {
      url = "github:nix-community/NUR";
    };
  };

  outputs = inputs @{ self, nixpkgs, home-manager, flake-utils, nur, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      user = "morp";
      # home = builtins.getEnv "HOME";

      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };

    in
    {

      # NixOS configurations
      # nixosConfigurations = (
      #   import ./hosts {
      #     inherit (nixpkgs) lib;
      #     inherit inputs nixpkgs home-manager flake-utils nur;
      #   }
      # );

      nixosConfigurations = {
        xps17 = lib.nixosSystem {
          inherit system;

          modules = [ ./hosts/xps17];
        };
      };

      # darwinConfigurations = (                                              # Darwin Configurations
      #   import ./darwin {
      #     inherit (nixpkgs) lib;
      #     inherit inputs nixpkgs home-manager darwin user;
      #   }
      # );
      #
      # homeConfigurations = (                                                # Non-NixOS configurations
      #   import ./nix {
      #     inherit (nixpkgs) lib;
      #     inherit inputs nixpkgs home-manager nixgl user;
      #   }
      # );

    };
}
