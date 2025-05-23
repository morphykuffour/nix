{
  home-manager,
  alejandra,
  agenix,
  self,
  nixpkgs,
  inputs,
  user,
  # neovim,
  ...
}:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {inherit inputs;};
  modules = [
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
          inherit inputs user;
        };
      };

      nixpkgs.overlays = [
        (import (builtins.fetchTarball {
          url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
        }))
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
