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

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    discord = {
      url = "github:InternetUnexplorer/discord-overlay";
    };

  };

  outputs = inputs @{ self, nixpkgs, home-manager, darwin, flake-utils, discord, ... }:
    let
      lib = nixpkgs.lib;
      user = "morp";
      # localOverlay = import ./overlay.nix; # TODO fix with proper overlay
      # overlays = [ 
      #   discord
      #     wsl-nixos
      #   ];

      pkgsForSystem = system: import nixpkgs {
        config = { allowUnfree = true; };
        inherit system;
      };

      # mkHomeConfiguration = args: home-manager.lib.homeManagerConfiguration (rec {
      #   system = args.system or "x86_64-linux";
      #   # configuration = import ./home.nix;
      #   modules = [
      #     ./home.nix
      #     ./hosts/xps17
      #   ];
      #   # homeDirectory = "/home/morp";
      #   # username = "morp";
      #   pkgs = pkgsForSystem system;
      # } // args);

    in
    flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (system: rec {
        legacyPackages = pkgsForSystem system;
      }) // {

      defaultPackage.x86_64-linux = self.morp;
      nixosConfigurations = {
        xps17 = lib.nixosSystem {
          # system = "x86_64-linux";
          modules = [ ./hosts/xps17 ];
        };

        wsl-nixos = lib.nixosSystem {
          # system = "x86_64-linux";
          modules = [ ./hosts/wsl ];
        };

        mac-mini = lib.nixosSystem {
          system = "aarch64-darwin";
          modules = [ ./hosts/mac_mini ];
        };
      };

      # homeConfigurations.xps17 = mkHomeConfiguration {
      #   extraSpecialArgs = {
      #     withGUI = true;
      #     isDesktop = true;
      #     networkInterface = "wlp0s20f3";
      #     # inherit localOverlay;
      #   };
      # };

      # homeConfigurations.wsl-nixos = mkHomeConfiguration {
      #   extraSpecialArgs = {
      #     withGUI = true;
      #     isDesktop = true;
      #     networkInterface = "wlp0s20f3";
      #     # inherit wslOverlay;
      #   };
      # };

      # homeConfigurations.mac-mini = mkHomeConfiguration {
      #   system = "aarch64-darwin";
      #   extraSpecialArgs = {
      #     withGUI = false;
      #     isDesktop = false;
      #     networkInterface = "en1";
      #     # inherit localOverlay;
      #   };
      # };

      inherit home-manager;
    };
}
