{
  home-manager,
  alejandra,
  agenix,
  self,
  nixpkgs,
  inputs,
  user,
  # overlays,
  # neovim,
  ...
}:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  # specialArgs = inputs;
  specialArgs = {inherit inputs;};
  modules = [
    ./configuration.nix
    ../../modules/protonvpn.nix
    # nixosModules.protonvpn = import ./modules/protonvpn.nix;
    inputs.hyprland.nixosModules.default
    home-manager.nixosModules.home-manager
    agenix.nixosModules.default
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${user}.imports = [
          ./home.nix
          # inputs.hyprland.homeManagerModules.default
          # {wayland.windowManager.hyprland.enable = true;}
        ];
        extraSpecialArgs = {
          plover = inputs.plover.packages."x86_64-linux".plover;
          inherit inputs user;
        };
      };

      nixpkgs.overlays = [
        # discord.overlays.default
        (import ./overlays/brave-nightly.nix)
        (import (builtins.fetchTarball {
          url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
        }))
        # plover.overlay
      ];

      environment.systemPackages = [
        alejandra.defaultPackage.x86_64-linux
        agenix.packages.x86_64-linux.default
        # inputs.neovim.packages.x86_64-linux.neovim # NVIM v0.9-dev
      ];
    }
  ];
}
