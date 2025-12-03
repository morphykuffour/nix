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

      # Get vendored dependencies
      cargoVendorDir = crane.cargoVendorDir { inherit src; };
      
      # Build cargo dependencies manually with full environment control
      cargoArtifacts = prev.stdenv.mkDerivation {
        name = "vertd-deps";
        inherit src;
        
        nativeBuildInputs = commonArgs.nativeBuildInputs ++ [
          prev.cargo
          prev.rustc
        ];
        buildInputs = commonArgs.buildInputs;
        
        # Environment variables - Nix will set these in the build environment
        PKG_CONFIG_PATH = "${prev.openssl.dev}/lib/pkgconfig";
        OPENSSL_DIR = "${prev.openssl.dev}";
        OPENSSL_LIB_DIR = "${prev.openssl.out}/lib";
        OPENSSL_INCLUDE_DIR = "${prev.openssl.dev}/include";
        
        configurePhase = ''
          # Copy vendored dependencies
          cp -r ${cargoVendorDir} vendor
          
          # Configure Cargo to use vendored sources
          mkdir -p .cargo
          cat > .cargo/config.toml <<EOF
          [source.crates-io]
          replace-with = "vendored-sources"
          
          [source.vendored-sources]
          directory = "$(pwd)/vendor"
          EOF
          
          # Set up environment (redundant but ensures it's set)
          export PKG_CONFIG_PATH="${prev.openssl.dev}/lib/pkgconfig"
          export OPENSSL_DIR="${prev.openssl.dev}"
          export OPENSSL_LIB_DIR="${prev.openssl.out}/lib"
          export OPENSSL_INCLUDE_DIR="${prev.openssl.dev}/include"
          
          # Verify environment
          echo "=== Environment Setup ==="
          echo "PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
          echo "PATH: $PATH"
          which pkg-config || (echo "ERROR: pkg-config not in PATH" && exit 1)
          pkg-config --version
          pkg-config --exists openssl || (echo "ERROR: openssl not found" && exit 1)
          echo "=== Environment OK ==="
        '';
        
        buildPhase = ''
          # Build dependencies using cargo build --lib
          # This builds the library and all its dependencies
          export CARGO_TARGET_DIR=$NIX_BUILD_TOP/target-deps
          cargo build --frozen --offline --lib
        '';
        
        installPhase = ''
          mkdir -p $out
          cp -r $CARGO_TARGET_DIR $out/target
        '';
        
        doCheck = false;
      };

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

