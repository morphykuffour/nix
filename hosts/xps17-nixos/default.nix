{
  home-manager,
  alejandra,
  agenix,
  self,
  nixpkgs,
  inputs,
  user,
  overlays,
  ...
}:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = inputs;
  modules = [
    # ./hosts/xps17-nixos
    ./configuration.nix
    ./hardware-configuration.nix
    # TODO: fix backup with borg
    # ./backup.nix
    ./tailscale.nix
    # TODO: move drive to zfs
    # ./zfs.nix
    # ../../modules/emacs
    agenix.nixosModules.default
    {
      nixpkgs.overlays = overlays;
    }
    {
      environment.systemPackages = [
        alejandra.defaultPackage.x86_64-linux
        agenix.packages.x86_64-linux.default
        # neovim.packages.x86_64-linux.neovim # NVIM v0.9-dev
      ];
    }
    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${user}.imports = [
          ./home.nix
          inputs.hyprland.homeManagerModules.default
        ];
        extraSpecialArgs = {
          plover = inputs.plover.packages."x86_64-linux".plover;
          inherit user;
        };
      };
    }
  ];
}
