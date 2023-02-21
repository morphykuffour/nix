{
  description = "Configurations targeting NixOS, Darwin, and WSL";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
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
    flake-utils.url = "github:numtide/flake-utils";

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
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # vscode-server.url = "github:msteen/nixos-vscode-server";
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
    flake-utils,
    neovim,
    discord,
    # vscode-server,
    ...
  } @ inputs: let
    user = "morp";
    overlays = [
      discord.overlays.default
      # plover.overlay
      # emacs-overlay.overlay
      # (import ./third_party/emacs-overlay)
      (import (builtins.fetchTarball {
        url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
        sha256 = "18mgdb2hhhak6s9xb3smw9rzw77x36wrpibdv9l088p6fv0rv6qp";
      }))
    ];
  in {

    # nix formatter
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;

    # mac_mini MacOs 
    darwinConfigurations.macmini-darwin = import ./hosts/macmini-darwin {
      inherit self nixpkgs darwin inputs user overlays home-manager alejandra;
    };

    # xps17 NixOs
    nixosConfigurations.xps17-nixos = import ./hosts/xps17-nixos {
      inherit nixpkgs self inputs user home-manager alejandra agenix overlays;
    };

    # optiplex NixOs
    nixosConfigurations.optiplex-nixos = import ./hosts/optiplex-nixos {
      inherit nixpkgs self inputs user home-manager alejandra agenix overlays;
    };

    # win-wsl NixOs
    nixosConfigurations.win-wsl = import ./hosts/win-wsl {
      inherit nixpkgs self inputs user home-manager alejandra agenix overlays;
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
    # https://myme.no/posts/2022-12-01-nixos-on-raspberrypi.html
    nixosConfigurations.rpi3b-nixos = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = inputs;
      modules = [
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        # ./hosts/rpi3b-nixos
        agenix.nixosModules.default
        {
          environment.systemPackages = [
            agenix.packages.x86_64-linux.default
          ];
        }
      ];
    };
  };
}
