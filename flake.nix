{
  description = "My Personal NixOS, Darwin, and WSL";

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

    wsl = {
      url = "gitbub:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    # nur = {
    #   url = "github:nix-community/NUR";
    # };
    #
    # nixGL = {
    #   url = "github:guibou/nixGL";
    #   flake = false;
    # };

    discord = {
      url = "github:InternetUnexplorer/discord-overlay";
    };

  };

  outputs = inputs @{ self, nixpkgs, home-manager, darwin, flake-utils, nur, nixGL, discord, ... }:
    let
      lib = nixpkgs.lib;
      user = "morp";
      # localOverlay = import ./overlay.nix; # TODO fix with proper overlay
      # home = builtins.getEnv "HOME";
      overlays = [ 
        discord
        wsl
      ];
      pkgs = import nixpkgs {
        # inherit system;
        config = { allowUnfree = true; };
      };

    in
    {
      homeConfigurations = {
        morp = inputs.home-manager.lib.homeManagerConfiguration {
          system = "x86_64-linux";
          homeDirectory = "/home/morp";
          username = "morp";
          stateVersion = "22.05";

          configuration = { config, pkgs, ... }:
            let
              overlay-unstable = final: prev: {
                unstable = inputs.nixpkgs-unstable.legacyPackages.x86_64-linux;
              };
            in
            {
              nixpkgs.overlays = [ overlay-unstable ];
              nixpkgs.config = {
                allowUnfree = true;
                # allowBroken = true;
              };

              imports = [ ./home.nix ];
            };
        };
      };
      morp = self.homeConfigurations.morp.activationPackage;
      defaultPackage.x86_64-linux = self.morp;
      nixosConfigurations = {
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

