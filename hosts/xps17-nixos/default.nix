{
  home-manager,
  alejandra,
  agenix,
  self,
  nixpkgs,
  inputs,
  user,
  overlays,
  # neovim,
  ...
}:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  # specialArgs = inputs;
  specialArgs = {inherit inputs;};
  modules = [
    ./configuration.nix
    ./hardware-configuration.nix
    ./tailscale.nix
    # inputs.hyprland.nixosModules.default
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

      nixpkgs.overlays = overlays;

      environment.systemPackages = [
        alejandra.defaultPackage.x86_64-linux
        agenix.packages.x86_64-linux.default
        inputs.neovim.packages.x86_64-linux.neovim # NVIM v0.9-dev
      ];
    }
  ];
}
