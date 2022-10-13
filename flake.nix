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

    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
    };

    # nixgl = {
    #   url = "github:guibou/nixGL";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    neovim = {
      url = "github:nix-community/neovim-nightly-overlay?ref=master";
    };

    discord = {
      url = "github:InternetUnexplorer/discord-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };

    plover = {
      url = "github:dnaq/plover-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alejandra = {
      url = "github:kamadorueda/alejandra/3.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    darwin,
    nur,
    discord,
    nixos-hardware,
    plover,
    alejandra,
    nixos-wsl,
    ...
  } @ inputs: let
    config = {
      allowBroken = true;
      allowUnfree = true;
      tarball-ttl = 0;
      contentAddressedByDefault = false;
    };

    lib = nixpkgs.lib;
    user = "morp";
    system = "x86_64-linux";

    pkgsForSystem = system:
      import nixpkgs {
        config = {allowUnfree = true;};
        inherit system;
      };
  in {
    overlays.default = with inputs;
      lib.composeManyExtensions [
        discord.overlays.default
        # nixGL.overlay
        # (final: prev: {
        #   mkNixGLWrappedApp = pkg: binName:
        #     prev.symlinkJoin {
        #       name = pkg.name + "-nixgl";
        #       paths = [
        #         (prev.writeShellScriptBin binName ''
        #           exec ${prev.nixgl.nixGLIntel}/bin/nixGLIntel \
        #             ${pkg}/bin/${binName} "$@"
        #         '')
        #         pkg
        #       ];
        #     };
        # })
        plover.overlay
        neovim.overlay
        nur.overlay
      ];

    # xps17 NixOs
    nixosConfigurations = {
      xps17-nixos = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/xps17-nixos
          nur.nixosModules.nur
          {
            environment.systemPackages = [
              alejandra.defaultPackage.${system}
            ];
          }

          # nixos-hardware.nixosModules.dell-xps-17-9700
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.morp = {
                imports = [./home.nix];
              };
              extraSpecialArgs = {
                plover = inputs.plover.packages."x86_64-linux".plover;
              };
            };
          }
        ];
        specialArgs = inputs;
      };

      # xps17 WSL TODO fix
      win-wsl = import ./hosts/windows-wsl {
        inherit config nixpkgs system nixos-wsl inputs;
      };
    };
    win-wsl = self.nixosConfigurations.win-wsl.config.system.build.toplevel;

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
