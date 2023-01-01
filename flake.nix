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
    tailscale = {
      url = "github:tailscale/tailscale";
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
    tailscale,
    neovim,
    ...
  } @ inputs: let
    user = "morp";
    overlays = [
      discord.overlays.default
      plover.overlay
    ];
  in {
    # nix formatter
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;

    # mac_mini Mac Os Monterey TODO fix
    darwinConfigurations."macmini-darwin" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./hosts/macmini-darwin
        {
          environment.systemPackages = [
            alejandra.defaultPackage.aarch64-darwin
            neovim.packages.aarch64-darwin.neovim
          ];
        }
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.morp = import ./hosts/macmini-darwin/home.nix;
        }
      ];
    };

    # xps17 NixOs
    nixosConfigurations.xps17-nixos = inputs.nixpkgs.lib.nixosSystem {
      # inherit overlays;
      system = "x86_64-linux";
      specialArgs = inputs;
      modules = [
        ./hosts/xps17-nixos
        agenix.nixosModule
        {
          environment.systemPackages = [
            alejandra.defaultPackage.x86_64-linux
            agenix.defaultPackage.x86_64-linux
            # neovim.packages.x86_64-linux.neovim # NVIM v0.9-dev
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
    };

    nixosConfigurations.optiplex-nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/optiplex-nixos
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
            # extraSpecialArgs = {
            #   plover = inputs.plover.packages."x86_64-linux".plover;
            # };
          };
        }
      ];
      specialArgs = inputs;
    };

    nixosConfigurations.win-wsl = nixpkgs.lib.nixosSystem {
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
    # https://github.com/NixOS/nixos-hardware/blob/9d87bc030a0bf3f00e953dbf095a7d8e852dab6b/starfive/visionfive/v1/README.md
    nixosConfigurations.riscv-vm = nixpkgs.lib.nixosSystem {
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

    # TODO: create vscode-server following
    # https://tailscale.com/kb/1166/vscode-ipad/
    nixosConfigurations.rpi3b-nixos = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = inputs;
      modules = [
        ./hosts/rpi3b-nixos
        agenix.nixosModule
        {
          environment.systemPackages = [
            alejandra.defaultPackage.x86_64-linux
            agenix.defaultPackage.x86_64-linux
            # neovim.packages.x86_64-linux.neovim
          ];
        }
      ];
    };
  };
}
