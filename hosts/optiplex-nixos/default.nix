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
  specialArgs = {inherit inputs;};
  modules = [
    ./configuration.nix
    ../../modules/tailscale
    agenix.nixosModules.default
    home-manager.nixosModules.home-manager

    # vertd module with package override for build dependencies
    # The vertd flake has a bug where buildDepsOnly doesn't get the nativeBuildInputs
    # So we need to override the package to fix the cargo dependency build
    ({pkgs, lib, ...}: let
      crane = inputs.vertd.inputs.crane.mkLib pkgs;
      src = crane.cleanCargoSource inputs.vertd;

      commonArgs = {
        inherit src;
        strictDeps = true;
        # Add build dependencies - openssl.dev in nativeBuildInputs so setup hooks run
        # This automatically sets up PKG_CONFIG_PATH
        nativeBuildInputs = [
          pkgs.pkg-config
          pkgs.openssl.dev
        ];
        buildInputs = [
          pkgs.openssl
        ];
        # Explicitly set environment variables as backup
        # The setup hooks should handle PKG_CONFIG_PATH, but we set it explicitly too
        preBuild = ''
          export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig"
          export OPENSSL_DIR="${pkgs.openssl.dev}"
          export OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib"
          export OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include"
        '';
      };

      # Build cargo dependencies with proper inputs
      cargoArtifacts = crane.buildDepsOnly commonArgs;

      # Build vertd with the artifacts
      vertd-fixed = crane.buildPackage (commonArgs // {
        inherit cargoArtifacts;
        nativeBuildInputs = commonArgs.nativeBuildInputs ++ [
          pkgs.makeWrapper
        ];
        postFixup = ''
          wrapProgram $out/bin/vertd --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ pkgs.libGL ]}"
        '';
        meta = {
          description = "VERT's solution to video conversion";
          homepage = "https://github.com/vert-sh/vertd";
          license = lib.licenses.gpl3;
          platforms = lib.platforms.linux;
          mainProgram = "vertd";
        };
      });
    in {
      nixpkgs.overlays = [
        (final: prev: {
          vertd = vertd-fixed;
        })
      ];
    })
    inputs.vertd.nixosModules.default
    ./vertd.nix
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

      environment.systemPackages = [
        alejandra.defaultPackage.x86_64-linux
        agenix.packages.x86_64-linux.default
        # neovim.packages.x86_64-linux.neovim
      ];
    }
  ];
}
