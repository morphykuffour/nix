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
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv.url = "github:cachix/devenv/v0.4";
    vscode-server.url = "github:msteen/nixos-vscode-server";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    darwin,
    discord,
    nixos-hardware,
    plover,
    alejandra,
    nixos-wsl,
    agenix,
    vscode-server,
    devenv,
    neovim,
    ...
  } @ inputs: {

    # nix formatter
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    # NixOS configurations
    nixosConfigurations = let
      # overlays
      overlays = [
        neovim.overlay
        discord.overlays.default
        plover.overlay
      ];
    in {
      nixpkgs.overlays = overlays;

      # xps17 NixOs
      xps17-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/xps17-nixos
          agenix.nixosModule
          {
            environment.systemPackages = [
              alejandra.defaultPackage.x86_64-linux
              agenix.defaultPackage.x86_64-linux
              devenv.packages.x86_64-linux.devenv
              neovim.packages.x86_64-linux.neovim
            ];
          }

          # nixos-hardware.nixosModules.dell-xps-17-9700
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.morp.imports = [./home.nix];
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
          vscode-server.nixosModule
          agenix.nixosModule
          {
            environment.systemPackages = [
              alejandra.defaultPackage.x86_64-linux
              agenix.defaultPackage.x86_64-linux
              neovim.packages.x86_64-linux.neovim
            ];
          }
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.morp.imports = [./home.nix];
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
              neovim.packages.x86_64-linux.neovim
            ];
          }
        ];
        specialArgs = inputs;
      };

      # TODO: move nvme1n1 ==> WDS100T1XHE-00AFY0 to VisionFive 2 SBC `lsblk -o name,model,serial`
      # TODO: install sbcl on SBC
      # TODO: install linux-kvm on SBC: https://github.com/kvm-riscv/howto/wiki/KVM-RISCV64-on-QEMU
      riscv-vm = nixpkgs.lib.nixosSystem {
        system = "riscv64-linux";
        modules = [
          {
            boot.supportedFilesystems = ["ext4"];
            boot.loader.grub.devices = [
              "/dev/disk/by-id/nvme-WDS100T1XHE-00AFY0_215070800985"
            ];

            fileSystems."/" = {
              device = "/dev/disk/by-id/nvme-WDS100T1XHE-00AFY0_215070800985";
              fsType = "ext4";
            };
          }
        ];
      };

      rpi3b-nixos = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./hosts/rpi3b-nixos
          {
            environment.systemPackages = [
              alejandra.defaultPackage.x86_64-linux
              neovim.packages.x86_64-linux.neovim
            ];
          }
        ];
        specialArgs = inputs;
      };

    };

    # mac_mini Mac Os Monterey TODO fix
    # Darwin configurations
    darwinConfigurations."macmini-darwin" = {
      mac_mini = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./hosts/mac-mini
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
