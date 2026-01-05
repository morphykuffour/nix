{
  home-manager,
  alejandra,
  agenix,
  self,
  nixpkgs,
  inputs,
  user,
  morph-emacs,
  # neovim,
  ...
}:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {inherit inputs;};
  modules = [
    ./configuration.nix
    ../../modules/tailscale
    home-manager.nixosModules.home-manager
    agenix.nixosModules.default
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
        inputs.emacs-overlay.overlays.default
        inputs.discord.overlays.default
      ];

      environment.systemPackages = [
        alejandra.defaultPackage.x86_64-linux
        agenix.packages.x86_64-linux.default
        # inputs.neovim.packages.x86_64-linux.neovim # NVIM v0.9-dev
      ];
    }
  ];
}
