{
  description = "Configurations targeting NixOS, Darwin, and WSL";

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
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      # nixpkgs.follows = "nixpkgs";
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
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    # vscode-server.url = "github:msteen/nixos-vscode-server";
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    nixified-ai = {
      url = "github:nixified-ai/flake";
    };
    fakwin = {
      url = "github:DMaroo/fakwin";
      flake = false;
    };
    vertd = {
      url = "github:VERT-sh/vertd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    darwin,
    plover,
    alejandra,
    nixos-wsl,
    agenix,
    tailscale,
    emacs-overlay,
    neovim,
    discord,
    nixos-hardware,
    nixified-ai,
    fakwin,
    vertd,
    ...
  } @ inputs: let
    user = "morph";
    overlays = [
      discord.overlays.default
      # plover.overlay
    ];

    # List of unix configurations
    configurations = [
      "xps17-nixos" # xps17 NixOs
      "optiplex-nixos" # optiplex NixOs
      "win-wsl" # win-wsl NixOs
    ];
  in {
    # nix formatter
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;

    # SD card image for Raspberry Pi 3B
    # NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix build .#packages.aarch64-darwin.rpi3b-sdcard --impure
    packages.aarch64-linux.rpi3b-sdcard = self.nixosConfigurations.rpi3b-nixos.config.system.build.sdImage;

    # mac_mini MacOs
    darwinConfigurations.macmini-darwin = import ./hosts/macmini-darwin {
      inherit self nixpkgs darwin inputs user home-manager alejandra agenix;
    };

    # xps17 NixOs
    nixosConfigurations.xps17-nixos = import ./hosts/xps17-nixos {
      inherit nixpkgs self inputs user home-manager alejandra agenix fakwin;
    };

    # t480 NixOs
    nixosConfigurations.t480-nixos = import ./hosts/t480-nixos {
      inherit nixpkgs self inputs user home-manager alejandra agenix;
    };

    # optiplex NixOs
    nixosConfigurations.optiplex-nixos = import ./hosts/optiplex-nixos {
      inherit nixpkgs self inputs user home-manager alejandra agenix overlays;
    };

    # win-wsl NixOs
    nixosConfigurations.win-wsl = import ./hosts/win-wsl {
      inherit nixpkgs self inputs user home-manager alejandra agenix overlays nixified-ai;
    };

    # visionfive2 NixOs
    # https://github.com/NixOS/nixos-hardware/tree/master/starfive/visionfive/v1
    # nixosConfigurations.visionfive2 = nixpkgs.lib.nixosSystem {
    #   system = "riscv64-linux";
    #   modules = [
    #     nixos-hardware.nixosModules.starfive-visionfive-v1
    #     {
    #       # with nix channel
    #       # imports = [<nixos-hardware/starfive/visionfive/v1/sd-image-installer.nix>];
    #
    #       nixpkgs.crossSystem = {
    #         config = "riscv64-unknown-linux-gnu";
    #         system = "riscv64-linux";
    #       };
    #     }
    #   ];
    # };

    # riscv-vm NixOS
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

    # rpi3b NixOS (cross-compile on Darwin → aarch64-linux)
    nixosConfigurations.rpi3b-nixos = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";

      # 2) tell Nix how to cross
      crossSystem = {
        system = "aarch64-unknown-linux-gnu";
        config = "aarch64-linux";
      };

      specialArgs = inputs;
      modules = [
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        nixos-hardware.nixosModules.raspberry-pi-3
        ./hosts/rpi3b-nixos
        agenix.nixosModules.default
        {
          nixpkgs.config.allowUnsupportedSystem = true;
          nixpkgs.config.allowBroken = true;
        }
      ];
    };
  };
}
