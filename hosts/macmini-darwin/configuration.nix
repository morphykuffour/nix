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
    ];
  };

  programs = {
    # Shell needs to be enabled
    zsh.enable = true;
  };

  services = {
    nix-daemon.enable = true; # Auto upgrade daemon
  };

  # homebrew = {
  #   # Declare Homebrew using Nix-Darwin
  #   enable = true;
  #   autoUpdate = true; # Auto update packages
  #   cleanup = "zap"; # Uninstall not listed packages and casks
  #   brews = [
  #   ];
  #   casks = [
  #     "plex-media-player"
  #   ];
  # };

  nix = {
    package = pkgs.nix;
    gc = {
      # Garbage collection
      automatic = true;
      interval.Day = 7;
      options = "--delete-older-than 7d";
    };
    extraOptions = ''
      auto-optimise-store = true
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
    # # insecure package needed for nixops
    # permittedInsecurePackages = [
    #   "python2.7-pyjwt-1.7.1"
    # ];
  };

  system = {
    defaults = {
      NSGlobalDomain = {
        # Global macOS system settings
        KeyRepeat = 1;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
      };
      dock = {
        # Dock settings
        autohide = true;
        orientation = "bottom";
        showhidden = true;
        tilesize = 40;
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
    activationScripts.postActivation.text = ''sudo chsh -s ${pkgs.zsh}/bin/zsh''; # Since it's not possible to declare default shell, run this command after build
    stateVersion = 4;
  };
}
