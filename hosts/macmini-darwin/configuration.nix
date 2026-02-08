{
  config,
  pkgs,
  ...
}: {
  imports = [
    # ../../modules/latex-ocr  # Temporarily disabled due to rapidfuzz build failure on macOS
    ../../modules/rawtalk
    ../../modules/emacs-daemon.nix
  ];

  users.users.morph = {
    home = "/Users/morph";
    shell = pkgs.zsh;
  };

  networking = {
    computerName = "macmini-darwin";
    hostName = "macmini-darwin";
  };

  # fonts = {
  #   # Fonts
  #   fontDir.enable = true;
  #   fonts = with pkgs; [
  #     source-code-pro
  #     font-awesome
  #     (nerdfonts.override {
  #       fonts = [
  #         "FiraCode"
  #         "JetBrainsMono"
  #       ];
  #     })
  #   ];
  # };

  environment = {
    shells = with pkgs; [zsh];
    variables = {
      # System variables
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    systemPackages = with pkgs; [
      # Installed Nix packages
      # Terminal
      git
      emacs
      fd
      ripgrep
      # PDF viewer setup
      duti
    ];
  };

  programs = {
    # Shell needs to be enabled
    zsh.enable = true;
  };

  homebrew = {
    # Temporarily disable nix-darwin Homebrew management to bypass bundle crash
    enable = true;
    global = {
      brewfile = false;
    };
    taps = [];
    onActivation = {
      autoUpdate = false;
      cleanup = "none";
      upgrade = false;
    };
    brews = [];
    casks = [];
  };

  nix = {
    package = pkgs.nix;
    # gc = {
    #   # Garbage collection
    #   automatic = true;
    #   interval.Day = 7;
    #   options = "--delete-older-than 7d";
    # };
    extraOptions = ''
      auto-optimise-store = true
      experimental-features = nix-command flakes
      gc-keep-outputs = true
      gc-keep-derivations = true
    '';
    enable = false;
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
    # # insecure package needed for nixops
    # permittedInsecurePackages = [
    #   "python2.7-pyjwt-1.7.1"
    # ];
  };

  nixpkgs.overlays = [
    (final: prev: {
      kitty = prev.kitty.overrideAttrs (old: {
        version = "0.43.1";
        __intentionallyOverridingVersion = true;
        doCheck = false;
      });
    })
  ];

  # LaTeX OCR Service
  # Temporarily disabled due to rapidfuzz build failure on macOS
  # services.latex-ocr = {
  #   enable = true;
  #   device = "mps"; # Use Apple Silicon GPU
  #   autoCopyToClipboard = true;
  #   outputFormat = "latex";
  #   verbose = false;
  # };

  # Rawtalk QMK Layer Switcher Service
  services.rawtalk = {
    enable = true;
  };

  # Emacs daemon service
  services.emacs-daemon = {
    enable = true;
    package = pkgs.emacs;  # This will use the Emacs from nixpkgs
    socketActivation = false;  # Start immediately on boot
  };

  system = {
    primaryUser = "morph";
    defaults = {
      NSGlobalDomain = {
        # Global macOS system settings
        KeyRepeat = 1;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;

        # Disable/reduce animations
        NSAutomaticWindowAnimationsEnabled = false; # Disable window open/close animations
        NSWindowResizeTime = 0.001; # Speed up window resize animations
        # "com.apple.mouse.linear" = true;  # Disable smooth scrolling - NOT SUPPORTED by nix-darwin
      };
      dock = {
        # Dock settings
        autohide = false;
        orientation = "bottom";
        showhidden = true;
        tilesize = 40;
        # mineffect = "genie";
        launchanim = false; # Disable Dock app launch animations
        # show-process-indicators = true;
        # show-recents = true;

        # Additional animation settings
        autohide-delay = 0.0; # Remove delay when showing/hiding Dock
        autohide-time-modifier = 0.0; # Remove animation when showing/hiding Dock
        expose-animation-duration = 0.1; # Speed up Mission Control animations
      };
      finder = {
        # Finder settings
        QuitMenuItem = false; # I believe this probably will need to be true if using spacebar
        # DisableAllAnimations = true;  # NOT SUPPORTED by nix-darwin

        # View and display settings
        AppleShowAllExtensions = true; # Show all file extensions
        ShowPathbar = true; # Show path bar at bottom
        ShowStatusBar = true; # Show status bar at bottom
        FXPreferredViewStyle = "Nlsv"; # Default view: Nlsv = List, icnv = Icon, clmv = Column, glyv = Gallery
        FXDefaultSearchScope = "SCcf"; # Search current folder by default
        FXEnableExtensionChangeWarning = false; # Disable warning when changing file extension
        _FXSortFoldersFirst = true; # Keep folders on top when sorting
      };
      trackpad = {
        # Trackpad settings
        Clicking = true;
        TrackpadRightClick = true;
      };
      spaces = {
        # Prevent other displays from going black when one is fullscreen
        spans-displays = true;
      };
    };
    keyboard = {
      enableKeyMapping = true; # Needed for skhd
    };
    # activationScripts.postActivation.text = ''
    #   sudo chsh -s ${pkgs.zsh}/bin/zsh
    #   # Setup Zathura PDF viewer if it's installed
    #   if command -v zathura &> /dev/null; then
    #     chmod +x ${./setup-zathura.sh}
    #     ${./setup-zathura.sh}
    #   fi
    # ''; # Since it's not possible to declare default shell, run this command after build

    # Finder configuration activation script
    activationScripts.postActivation.text = ''
      # Run user-specific Finder configuration as the morph user
      sudo -u morph bash -c '
        # Configure Finder to sort by Date Modified (newest first)
        defaults write com.apple.finder FXPreferredGroupBy -string "Date Modified"

        # Remove .DS_Store files to force Finder to use new defaults
        # Only remove from common user directories to avoid system issues
        find ~/Documents ~/Downloads ~/Desktop -name ".DS_Store" -depth -exec rm {} \; 2>/dev/null || true

        # Restart Finder to apply changes
        killall Finder 2>/dev/null || true
      '
    '';

    stateVersion = 4;
  };
}
