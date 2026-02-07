{
  home-manager,
  agenix,
  self,
  nixpkgs,
  inputs,
  user,
  overlays,
  morph-emacs,
  emacs-overlay,
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
    # VERT configuration is now consolidated in vert.nix (loaded via configuration.nix)
    # ./vertd-package.nix  # Moved to vert.nix
    # inputs.vertd.nixosModules.default  # Not used - using Docker instead
    # ./vertd.nix  # Moved to vert.nix
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${user}.imports = [
          ./home.nix
        ];
        sharedModules = [
          morph-emacs.homeManagerModules.default
        ];
        extraSpecialArgs = {
          plover = inputs.plover.packages."x86_64-linux".plover;
          inherit inputs user;
        };
      };

      nixpkgs.overlays = [
        emacs-overlay.overlays.default
        # Fix rustdesk webm-sys C++ compilation issue with GCC 15
        (final: prev: {
          rustdesk = prev.rustdesk.overrideAttrs (old: {
            preBuild =
              (old.preBuild or "")
              + ''
                # Patch webm-sys for GCC 15 compatibility
                echo "=== Patching webm-sys C++ files for GCC 15 ==="

                # The vendor directory is at /build/rustdesk-1.4.4-vendor/
                if [ -d "/build/rustdesk-1.4.4-vendor/webm-sys-1.0.4" ]; then
                  echo "Found webm-sys-1.0.4 in vendor directory, patching..."
                  find /build/rustdesk-1.4.4-vendor/webm-sys-1.0.4 -type f -name "*.cc" -print -exec sed -i '1i#include <cstdint>' {} \;
                  find /build/rustdesk-1.4.4-vendor/webm-sys-1.0.4 -type f -name "*.h" -print -exec sed -i '1i#include <cstdint>' {} \; || true
                  echo "Patching complete!"
                else
                  echo "WARNING: webm-sys-1.0.4 not found in vendor directory"
                fi
              '';
          });
        })
      ];

      environment.systemPackages = with nixpkgs.legacyPackages.x86_64-linux; [
        alejandra
        agenix.packages.x86_64-linux.default
        # neovim.packages.x86_64-linux.neovim
      ];
    }
  ];
}
