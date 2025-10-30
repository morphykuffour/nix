{
  config,
  pkgs,
  ...
}: {
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
      # emacs
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
    # Manage Homebrew packages via nix-darwin
    enable = true;
    autoUpdate = true;
    cleanup = "zap";
    brews = [
      "jellyfin"
      "ffmpeg"
    ];
    casks = [];
  };

  launchd.user.agents.jellyfin = {
    enable = true;
    config = {
      ProgramArguments = [
        "/opt/homebrew/bin/jellyfin"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      WorkingDirectory = config.users.users.morph.home;
      StandardOutPath = "${config.users.users.morph.home}/Library/Logs/jellyfin.log";
      StandardErrorPath = "${config.users.users.morph.home}/Library/Logs/jellyfin.err.log";
      ProcessType = "Background";
    };
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

  system = {
    primaryUser = "morph";
    defaults = {
      NSGlobalDomain = {
        # Global macOS system settings
        KeyRepeat = 1;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
      };
      dock = {
        # Dock settings
        autohide = false;
        orientation = "right";
        showhidden = true;
        tilesize = 40;
        # mineffect = "genie";
        # launchanim = true;
        # show-process-indicators = true;
        # show-recents = true;
      };
      finder = {
        # Finder settings
        QuitMenuItem = false; # I believe this probably will need to be true if using spacebar
      };
      trackpad = {
        # Trackpad settings
        Clicking = true;
        TrackpadRightClick = true;
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
    stateVersion = 4;
  };
}
