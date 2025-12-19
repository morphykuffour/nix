{
  alejandra,
  user,
  nixpkgs,
  darwin,
  inputs,
  home-manager,
  agenix,
  morph-emacs,
  emacs-overlay,
  ...
}:
darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [
    ./configuration.nix
    {
      environment.systemPackages = [
        alejandra.packages.aarch64-darwin.default
        agenix.packages.aarch64-darwin.default
        # neovim.packages.aarch64-darwin.neovim
      ];
    }
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.morph = import ./home.nix;
      home-manager.sharedModules = [
        morph-emacs.homeManagerModules.default
      ];
    }
    {
      nixpkgs.overlays = [emacs-overlay.overlays.default];
    }
  ];
}
