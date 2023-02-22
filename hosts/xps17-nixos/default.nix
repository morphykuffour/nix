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
    ./configuration.nix
    ./hardware-configuration.nix
    ./tailscale.nix
    inputs.hyprland.nixosModules.default
    home-manager.nixosModules.home-manager
    agenix.nixosModules.default
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

      nixpkgs.overlays = overlays;

      environment.systemPackages = [
        alejandra.defaultPackage.x86_64-linux
        agenix.packages.x86_64-linux.default
        # neovim.packages.x86_64-linux.neovim # NVIM v0.9-dev
      ];
    }
  ];
}
