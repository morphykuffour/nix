{
  home-manager,
  alejandra,
  agenix,
  self,
  nixpkgs,
  inputs,
  user,
  overlays,
  morph-emacs,
  emacs-overlay,
  ...
}:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {inherit inputs;};
  modules = [
    ./configuration.nix
    ../../modules/tailscale
    agenix.nixosModules.default
    home-manager.nixosModules.home-manager
    # VERT configuration is now consolidated in vert.nix (loaded via configuration.nix)
    # ./vertd-package.nix  # Moved to vert.nix
    # inputs.vertd.nixosModules.default  # Not used - using Docker instead
    # ./vertd.nix  # Moved to vert.nix
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${user}.imports = [
          ./home.nix
        ];
        sharedModules = [
          morph-emacs.homeManagerModules.default
        ];
        extraSpecialArgs = {
          plover = inputs.plover.packages."x86_64-linux".plover;
          inherit inputs user;
        };
      };

      nixpkgs.overlays = [
        emacs-overlay.overlays.default
      ];

      environment.systemPackages = [
        alejandra.defaultPackage.x86_64-linux
        agenix.packages.x86_64-linux.default
        # neovim.packages.x86_64-linux.neovim
      ];
    }
  ];
}
