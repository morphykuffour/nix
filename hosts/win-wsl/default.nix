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
    # ./hosts/win-wsl
    ./configuration.nix
    nixos-wsl.nixosModules.wsl
    # vscode-server.nixosModule
    {
      environment.systemPackages = [
        alejandra.defaultPackage.x86_64-linux
        # neovim.packages.x86_64-linux.neovim
      ];
    }
    # home-manager.nixosModules.home-manager
    # {
    #   home-manager = {
    #     useGlobalPkgs = true;
    #     useUserPackages = true;
    #     users.${user}.imports = [./home.nix];
    #     # extraSpecialArgs = {
    #     #   plover = inputs.plover.packages."x86_64-linux".plover;
    #     # };
    #   };
    # }
  ];
  specialArgs = inputs;
}
