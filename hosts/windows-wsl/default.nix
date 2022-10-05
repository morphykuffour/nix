{ config, nixpkgs, pkgs, nixos-wsl, overlays, inputs, ... }: 

nixpkgs.lib.nixosSystem rec {
  system = "x86_64-linux";

  modules = [
    nixos-wsl.nixosModules.wsl

    {
      nixpkgs = { inherit config overlays; };
      networking.hostName = "xps17-nixos";
      system.stateVersion = "22.05";

      wsl = {
        enable = true;
        automountPath = "/mnt";
        defaultUser = "morp";
        startMenuLaunchers = true;
        wslConf.network.hostname = "xps17-wsl";

        # Enable integration with Docker Desktop (needs to be installed)
        docker.enable = true;
      };
    }

    ./configuration.nix
  ];

  specialArgs = { inherit inputs system; };
}
