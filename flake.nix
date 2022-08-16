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

    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    nur = {
      url = "github:nix-community/NUR";
    };

   homeManagerConfig = {
      url = "path:/home/morp/nix/home.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @{ self, nixpkgs, home-manager, darwin, flake-utils, nur, homeManagerConfig, ... }:
    let
      lib = nixpkgs.lib;
      user = "morp";
      # home = builtins.getEnv "HOME";

      pkgs = import nixpkgs {
        # inherit system;
        config = { allowUnfree = true; };
      };

    in
    {
      # homeManagerConfigurations = {
      #   "morp" = home-manager.lib.homeManagerConfiguration {
      #     inherit pkgs;
      #     configuration = {
      #       imports = [
      #         ./home.nix
      #       ];
      #     };
      #     system = "x86_64-linux";
      #     homeDirectory = "/home/morp";
      #     username = user;
      #     stateVersion = "22.05";
      #   };
      # };

      nixosConfigurations = {
      inherit (homeManagerConfig) homeConfigurations;
        xps17 = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./hosts/xps17 ];
        };
      };

      darwinConfigurations = {
        # "Morphys-mac_mini" = darwin.lib.darwinSystem {
        mac_mini = darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = [ ./hosts/mac_mini ];
        };
      };

    };
}

