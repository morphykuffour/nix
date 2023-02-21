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
    # ./hosts/macmini-darwin
    ./darwin-configuration.nix
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
      home-manager.users.${user} = import ./home.nix;
    }
  ];
}
