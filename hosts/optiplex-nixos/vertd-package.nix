{
  config,
  pkgs,
  lib,
  ...
} @ args: let
  # Access inputs from specialArgs
  inputs = args.inputs or (throw "inputs must be provided via specialArgs");
in {
  # vertd package override module
  # The vertd flake has a bug where buildDepsOnly doesn't get the nativeBuildInputs
  # So we need to override the package to fix the cargo dependency build
  nixpkgs.overlays = [
    (final: prev: let
      crane = inputs.vertd.inputs.crane.mkLib prev;
      src = crane.cleanCargoSource inputs.vertd;

      commonArgs = {
        inherit src;
        strictDeps = true;
        # Add build dependencies - openssl.dev in nativeBuildInputs so setup hooks run
        nativeBuildInputs = [
          prev.pkg-config
          prev.openssl.dev
        ];
        buildInputs = [
          prev.openssl
        ];
      };

      # Build cargo dependencies using Crane but with proper environment
      # Use preConfigure which runs before configurePhase
      cargoArtifacts = crane.buildDepsOnly (commonArgs // {
        # Set environment variables as attributes
        PKG_CONFIG_PATH = "${prev.openssl.dev}/lib/pkgconfig";
        OPENSSL_DIR = "${prev.openssl.dev}";
        OPENSSL_LIB_DIR = "${prev.openssl.out}/lib";
        OPENSSL_INCLUDE_DIR = "${prev.openssl.dev}/include";
        
        # Use preConfigure to set up environment before any build steps
        preConfigure = ''
          export PKG_CONFIG_PATH="${prev.openssl.dev}/lib/pkgconfig"
          export OPENSSL_DIR="${prev.openssl.dev}"
          export OPENSSL_LIB_DIR="${prev.openssl.out}/lib"
          export OPENSSL_INCLUDE_DIR="${prev.openssl.dev}/include"
          export PATH="${lib.makeBinPath (commonArgs.nativeBuildInputs)}:$PATH"
          
          # Debug: verify environment
          echo "PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
          echo "PATH: $PATH"
          which pkg-config || echo "WARNING: pkg-config not in PATH"
          pkg-config --version || echo "WARNING: pkg-config failed"
        '';
        
        # Also set in preBuild as backup
        preBuild = ''
          export PKG_CONFIG_PATH="${prev.openssl.dev}/lib/pkgconfig"
          export OPENSSL_DIR="${prev.openssl.dev}"
          export OPENSSL_LIB_DIR="${prev.openssl.out}/lib"
          export OPENSSL_INCLUDE_DIR="${prev.openssl.dev}/include"
        '';
      });

      # Build vertd with the artifacts
      vertd-fixed = crane.buildPackage (commonArgs // {
        inherit cargoArtifacts;
        nativeBuildInputs = commonArgs.nativeBuildInputs ++ [
          prev.makeWrapper
        ];
        # Set environment variables for the final build too
        PKG_CONFIG_PATH = "${prev.openssl.dev}/lib/pkgconfig";
        OPENSSL_DIR = "${prev.openssl.dev}";
        OPENSSL_LIB_DIR = "${prev.openssl.out}/lib";
        OPENSSL_INCLUDE_DIR = "${prev.openssl.dev}/include";
        postFixup = ''
          wrapProgram $out/bin/vertd --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ prev.libGL ]}"
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
      vertd = vertd-fixed;
    })
  ];
}

