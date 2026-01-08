{
  home-manager,
  agenix,
  self,
  nixpkgs,
  inputs,
  user,
  overlays,
  nixified-ai,
  ...
}:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    # ./hosts/win-wsl
    ./configuration.nix
    inputs.nixos-wsl.nixosModules.wsl
    # vscode-server.nixosModule
    {
      environment.systemPackages = with nixpkgs.legacyPackages.x86_64-linux; [
        alejandra
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
  specialArgs =
    inputs
    // {
      agenix = agenix;
      nixified-ai = nixified-ai;
    };
}
