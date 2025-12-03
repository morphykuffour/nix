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
  
  # Override the package before the vertd module evaluates
  # This ensures our package is used instead of the flake's default
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

      # Build cargo dependencies manually with full environment control
      # We'll let cargo fetch dependencies normally (no vendoring needed for deps-only build)
      cargoArtifacts = prev.stdenv.mkDerivation {
        name = "vertd-deps-manual-openssl-fix";
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
          # Set up environment
          export PKG_CONFIG_PATH="${prev.openssl.dev}/lib/pkgconfig"
          export OPENSSL_DIR="${prev.openssl.dev}"
          export OPENSSL_LIB_DIR="${prev.openssl.out}/lib"
          export OPENSSL_INCLUDE_DIR="${prev.openssl.dev}/include"
          
          # Verify environment
          echo "=== Environment Setup ==="
          echo "PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
          echo "PATH: $PATH"
          # Check if pkg-config is available (use command -v, a bash builtin)
          if ! command -v pkg-config >/dev/null 2>&1; then
            echo "ERROR: pkg-config not found in PATH"
            exit 1
          fi
          echo "pkg-config found, testing..."
          pkg-config --version || (echo "ERROR: pkg-config failed" && exit 1)
          pkg-config --exists openssl || (echo "ERROR: openssl not found" && exit 1)
          echo "=== Environment OK ==="
        '';
        
        buildPhase = ''
          # Build dependencies using cargo build --lib
          # This builds the library and all its dependencies
          # We use --locked to ensure reproducible builds
          export CARGO_TARGET_DIR=$NIX_BUILD_TOP/target-deps
          cargo build --locked --lib
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

