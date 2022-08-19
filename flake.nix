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

    discord = {
      url = "github:InternetUnexplorer/discord-overlay";
    };

  };

  outputs = inputs @{ self, nixpkgs, home-manager, darwin, discord, ... }:
    let
      lib = nixpkgs.lib;
      user = "morp";
      # overlays = import ./overlay.nix; # TODO fix 

      pkgsForSystem = system: import nixpkgs {
        config = { allowUnfree = true; };
        inherit system;
      };
    in
    {
      nixosConfigurations = {
        xps17 = lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            ./hosts/xps17 
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.morp = import ./home.nix;

            # Optionally, use home-manager.extraSpecialArgs to pass arguments to home.nix
            # home-manager.extraSpecialArgs
          }
          ];
          specialArgs = inputs;
          # inherit overlays;
        };

      };

      nixosConfigurations = {
        wsl-nixos = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./hosts/wsl ];
        };

      };

      nixosConfigurations = {
        mac-mini = lib.nixosSystem {
          system = "aarch64-darwin";
          modules = [ ./hosts/mac_mini ];
        };
      };

      inherit home-manager;
    };
}
