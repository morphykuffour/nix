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

    nur = {
      url = "github:nix-community/NUR";
    };

    neovim = {
      url = "github:nix-community/neovim-nightly-overlay";
    };

    discord = {
      url = "github:InternetUnexplorer/discord-overlay";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };
  };

  outputs = { self, nixpkgs, home-manager, darwin, nur, discord, nixos-hardware, ... }@inputs:
    let
      lib = nixpkgs.lib;
      user = "morp";
      system = "x86_64-linux";

      pkgsForSystem = system: import nixpkgs {
        config = { allowUnfree = true; };
        inherit system;
      };

      # Overlays from ./overlays directory
      # overlays = with inputs; [
        # emacs.overlay
      # ]
      # Overlays from ./overlays directory
      # ++ (importNixFiles ./overlays);

    in
    {
      # xps17 NixOs
      nixosConfigurations = {
        xps17-nixos = lib.nixosSystem {
          inherit system;
          # specialArgs = { inherit inputs user overlays; };
          modules = [
            ./hosts/xps17-nixos
            nur.nixosModules.nur
            # nixos-hardware.nixosModules.dell-xps-17-9700
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              # home-manager.extraSpecialArgs = { inherit user; };
              # home-manager.users.${user} = {
              home-manager.users.morp = {
                imports = [ ./home.nix ];
              };
            }
          ];
          specialArgs = inputs;
        };

        xps17-wsl = lib.nixosSystem {
          system = "x86_64-linux";

          modules = [ ./hosts/xps17-wsl ];
          nixpkgs.overlays = [
            (import (builtins.fetchTarball {
              url = "https://github.com/InternetUnexplorer/discord-overlay/archive/main.tar.gz";
            }))

          ];
        };

      };

      # mac_mini Mac Os Monterey TODO fix
      darwinConfigurations = {
        mac_mini = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./hosts/mac_mini
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.morp = import ./home.nix;
            }
          ];
        };
      };
    };
}
