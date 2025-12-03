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
        nativeBuildInputs = [
          pkgs.pkg-config
          pkgs.openssl.dev
        ];
        buildInputs = [
          pkgs.openssl
        ];
      };

      # Build cargo dependencies with proper inputs
      # Override the derivation to ensure environment variables are available
      cargoArtifacts = (crane.buildDepsOnly commonArgs).overrideAttrs (oldAttrs: {
        # Add environment variables to the build environment
        PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
        OPENSSL_DIR = "${pkgs.openssl.dev}";
        OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
        OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
        
        # Ensure preBuild runs and sets up the environment
        preBuild = (oldAttrs.preBuild or "") + ''
          export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig"
          export OPENSSL_DIR="${pkgs.openssl.dev}"
          export OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib"
          export OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include"
          export PATH="${lib.makeBinPath [ pkgs.pkg-config ]}:$PATH"
        '';
      });

      # Build vertd with the artifacts
      vertd-fixed = crane.buildPackage (commonArgs // {
        inherit cargoArtifacts;
        nativeBuildInputs = commonArgs.nativeBuildInputs ++ [
          pkgs.makeWrapper
        ];
        # Set environment variables for the final build too
        PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
        OPENSSL_DIR = "${pkgs.openssl.dev}";
        OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
        OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
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
