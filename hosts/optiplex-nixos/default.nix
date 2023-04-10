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
  modules = [
    # ./hosts/optiplex-nixos
    ./configuration.nix
    agenix.nixosModules.default
    {
      environment.systemPackages = [
        alejandra.defaultPackage.x86_64-linux
        agenix.packages.x86_64-linux.default
        # neovim.packages.x86_64-linux.neovim
      ];
    }
    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        # users.${user}.imports = [./home.nix];
        # extraSpecialArgs = {
        #   plover = inputs.plover.packages."x86_64-linux".plover;
        # };
      };
    }
  ];
  specialArgs = inputs;
}
