{
  home-manager,
  agenix,
  self,
  nixpkgs,
  inputs,
  user,
  fakwin,
  morph-emacs,
  emacs-overlay,
  # neovim,
  ...
}:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {inherit inputs;};
  modules = [
    # Hardware-specific tuning for Dell XPS 17 9700 with NVIDIA dGPU
    inputs.nixos-hardware.nixosModules.dell-xps-17-9700-nvidia

    ./configuration.nix
    # ../../modules/wg-quick
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
          inherit inputs user fakwin;
        };
      };

      # Overlays: override deskflow to 1.25.0 (protocol match with macOS)
      nixpkgs.overlays = [
        emacs-overlay.overlays.default
        (final: prev: {
          deskflow = prev.callPackage ../../pkgs/deskflow {};
        })
      ];

      environment.systemPackages = [
        inputs.nixpkgs.legacyPackages.x86_64-linux.alejandra
        agenix.packages.x86_64-linux.default
        # inputs.neovim.packages.x86_64-linux.neovim # NVIM v0.9-dev
      ];
    }
  ];
}
