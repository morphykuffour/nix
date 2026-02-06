{
  user,
  nixpkgs,
  darwin,
  inputs,
  home-manager,
  agenix,
  morph-emacs,
  emacs-overlay,
  rawtalk,
  ...
}:
darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  specialArgs = {inherit rawtalk;};
  modules = [
    ./configuration.nix
    {
      environment.systemPackages = with nixpkgs.legacyPackages.aarch64-darwin; [
        alejandra
        agenix.packages.aarch64-darwin.default
        rawtalk.packages.aarch64-darwin.default
        # neovim.packages.aarch64-darwin.neovim
      ];
    }
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.morph = import ./home.nix;
      # Temporarily disabled to prevent symlinking source files
      # home-manager.sharedModules = [
      #   morph-emacs.homeManagerModules.default
      # ];
      home-manager.backupFileExtension = "backup";
    }
    {
      nixpkgs.overlays = [emacs-overlay.overlays.default];
    }
  ];
}
