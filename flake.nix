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

    # TODO get nvidia prime offloading to work
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

    # TODO fix
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server.url = "github:msteen/nixos-vscode-server";
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
    agenix,
    vscode-server,
    ...
  } @ inputs: {
    nixosConfigurations = let
      defaultModules = [
        home-manager.nixosModules.home-manager
        ({
          config,
          lib,
          lib',
          ...
        }: {
          config = {
            _module.args = {
              lib' = lib // import ./lib {inherit config lib;};
            };

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.morp.imports = [./home-manager/home.nix];
            };
          };
        })
      ];
    in {
      # overlays
      overlays.default = with inputs;
        nixpkgs.lib.composeManyExtensions [
          discord.overlays.default
          plover.overlay
          neovim.overlay
          nur.overlay
        ];

      # xps17 NixOs
      xps17-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/xps17-nixos
          nur.nixosModules.nur
          agenix.nixosModule
          {
            environment.systemPackages = [
              alejandra.defaultPackage.x86_64-linux
              agenix.defaultPackage.x86_64-linux
            ];
          }

          # nixos-hardware.nixosModules.dell-xps-17-9700
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.morp.imports = [./home-manager/home.nix];
              extraSpecialArgs = {
                plover = inputs.plover.packages."x86_64-linux".plover;
              };
            };
          }
        ];
        specialArgs = inputs;
      };

      optiplex-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/optiplex-nixos
          nur.nixosModules.nur
          vscode-server.nixosModule
          {
            environment.systemPackages = [
              alejandra.defaultPackage.x86_64-linux
              agenix.defaultPackage.x86_64-linux
            ];
          }
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.morp.imports = [./home-manager/home.nix];
              extraSpecialArgs = {
                plover = inputs.plover.packages."x86_64-linux".plover;
              };
            };
          }
        ];
        specialArgs = inputs;
      };

      win-wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/win-wsl
          nixos-wsl.nixosModules.wsl
          vscode-server.nixosModule
          {
            environment.systemPackages = [
              alejandra.defaultPackage.x86_64-linux
            ];
          }
        ];
        # ++ defaultModules;
        specialArgs = inputs;
      };

      # mac_mini Mac Os Monterey TODO fix
      darwinConfigurations = {
        mac_mini = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./hosts/mac-mini
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.morp = import ./home-manager/home.nix;
            }
          ];
        };
      };
    };
  };
}
