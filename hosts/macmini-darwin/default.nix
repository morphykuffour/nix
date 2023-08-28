{
  alejandra,
  user,
  nixpkgs,
  darwin,
  inputs,
  home-manager,
  ...
}:
darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [
    ./configuration.nix
    {
      environment.systemPackages = [
        alejandra.defaultPackage.aarch64-darwin
        # neovim.packages.aarch64-darwin.neovim
      ];
    }
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.morp = import ./home.nix;
    }
  ];
}
