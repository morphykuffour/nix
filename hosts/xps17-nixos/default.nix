{
  home-manager,
  alejandra,
  agenix,
  self,
  nixpkgs,
  inputs,
  user,
  fakwin,
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
        extraSpecialArgs = {
          plover = inputs.plover.packages."x86_64-linux".plover;
          inherit inputs user fakwin;
        };
      };

      # Temporarily disable overlays to avoid impure fetches during pure flake evaluation
      nixpkgs.overlays = [];

      environment.systemPackages = [
        alejandra.defaultPackage.x86_64-linux
        agenix.packages.x86_64-linux.default
        # inputs.neovim.packages.x86_64-linux.neovim # NVIM v0.9-dev
      ];
    }
  ];
}
