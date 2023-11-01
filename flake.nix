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
    hyprwm-contrib = {
      url = "github:hyprwm/contrib";
    };
    hyprland-protocols = {
      url = "github:hyprwm/hyprland-protocols";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xdph = {
      url = "github:hyprwm/xdg-desktop-portal-hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprland-protocols.follows = "hyprland-protocols";
    };
    # anyrun.url = "github:Kirottu/anyrun";
    # anyrun.inputs.nixpkgs.follows = "nixpkgs";
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
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # vscode-server.url = "github:msteen/nixos-vscode-server";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
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
    hyprland,
    hyprwm-contrib,
    hyprland-protocols,
    xdph,
    ...
  } @ inputs: let
    user = "morph";
    # Overlays provided by inputs
    overlays = [
      emacs-overlay.overlay
      discord.overlays.default
      (import ./overlays/brave-nightly.nix)
      # plover.overlay
    ];


    # List of unix configurations
    configurations = [
      "xps17-nixos" # xps17 NixOs
      "optiplex-nixos" # optiplex NixOs
      "win-wsl" # win-wsl NixOs
    ];
  in {

    # nixosModules.protonvpn = import ./modules/protonvpn.nix;

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

    # visionfive2 NixOs
    # https://github.com/NixOS/nixos-hardware/tree/master/starfive/visionfive/v1
    nixosConfigurations.visionfive2 = nixpkgs.lib.nixosSystem {
      system = "riscv64-linux";
      modules = [
        nixos-hardware.nixosModules.starfive-visionfive-v1
        {
          # with nix channel
          # imports = [<nixos-hardware/starfive/visionfive/v1/sd-image-installer.nix>];

          nixpkgs.crossSystem = {
            config = "riscv64-unknown-linux-gnu";
            system = "riscv64-linux";
          };
        }
      ];
    };

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

    # rpi3b NixOS
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
