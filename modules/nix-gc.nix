# Nix garbage collection configuration to preserve flake inputs
{ config, lib, pkgs, ... }:

{
  nix = {
    # Garbage collection settings
    gc = {
      automatic = true;
      interval = { Day = 7; };  # Run GC weekly
      options = "--delete-older-than 14d";  # Keep for at least 14 days
    };
    
    # Extra configuration to preserve flake inputs and build dependencies
    extraOptions = ''
      # Keep build dependencies
      keep-outputs = true
      keep-derivations = true
      
      # Minimum free space settings (optional - adjust as needed)
      min-free = ${toString (1 * 1024 * 1024 * 1024)}  # 1 GB
      max-free = ${toString (10 * 1024 * 1024 * 1024)} # 10 GB
      
      # Keep flake inputs pinned in the store
      keep-flake-inputs = true
      
      # Additional experimental features if not already set
      experimental-features = nix-command flakes
      
      # Auto-optimize the store to save space
      auto-optimise-store = true
    '';
    
    # Settings to help preserve flake dependencies
    settings = {
      # Keep build logs for debugging
      keep-build-log = true;
      
      # Ensure flake registry entries are kept
      flake-registry = pkgs.writeText "flake-registry.json" ''
        {
          "version": 2,
          "flakes": []
        }
      '';
    };
  };
}