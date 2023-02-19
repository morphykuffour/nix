{
  self,
  nixpkgs,
  inputs,
  user,
  ...
}: let
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true; # Allow proprietary software
  };

  lib = nixpkgs.lib;
in {
  # Laptop profile
  xps17-nixos = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs user;};
    modules = [
      ./xps17-nixos
      agenix.nixosModules.default
      {
        environment.systemPackages = [
          alejandra.defaultPackage.x86_64-linux
          agenix.packages.x86_64-linux.default
          # neovim.packages.x86_64-linux.neovim # NVIM v0.9-dev
        ];
      }
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${user} = {
            imports =
              [
                (import ./hosts/xps17-nixos/home.nix)
              ]
              ++ [
                inputs.hyprland.homeManagerModules.default
              ];
          };
          extraSpecialArgs = {
            plover = inputs.plover.packages."x86_64-linux".plover;
            inherit user;
          };
        };

        # nixpkgs = {
        #   overlays =
        #     (import ../overlays)
        #       ++ [
        #       self.overlays.default
        #       inputs.neovim-nightly-overlay.overlay
        #       inputs.rust-overlay.overlays.default
        #       inputs.picom.overlays.default
        #     ];
        # };
      }
    ];
  };
}
