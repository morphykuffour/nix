{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/rawtalk
    ../../modules/emacs-daemon.nix
    ../../modules/atomic-chrome.nix
    ../../modules/kanata
  ];

  users.users.morph = {
    home = "/Users/morph";
    shell = pkgs.zsh;
  };

  networking = {
    computerName = "mbp-darwin";
    hostName = "mbp-darwin";
  };

  environment = {
    shells = with pkgs; [zsh];
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    systemPackages = with pkgs; [
      git
      fd
      ripgrep
      duti
      bat
      stow
      tldr
      autojump
      starship
      opencode
      cachix
      gh
      fzf
      eza
      btop
      dog
      duf
      dust
      tokei
      delta
    ];
  };

  programs = {
    zsh.enable = true;
  };

  homebrew = {
    enable = true;
    global = {
      brewfile = false;
    };
    taps = [
      # "nikitabobko/tap"
      # "deskflow/tap"
    ];
    onActivation = {
      autoUpdate = false;
      cleanup = "none";
      upgrade = false;
    };
    brews = [];
    # GUI apps that require homebrew casks
    casks = [
      # "aerospace"
      "alt-tab"
      # "deskflow"
      "hiddenbar"
      "karabiner-elements"
      "keycastr"
      "raycast"
      "spotify"
      "utm"
    ];
  };

  nix = {
    package = pkgs.nix;
    extraOptions = ''
      auto-optimise-store = true
      experimental-features = nix-command flakes
      gc-keep-outputs = true
      gc-keep-derivations = true
      extra-substituters = https://jedimaster.cachix.org https://nix-community.cachix.org
      extra-trusted-public-keys = jedimaster.cachix.org-1:d3z8VEyrrqcYEe/9wOhIa6iXb4ArWUoQLB5tz1b+CZA= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
    '';
    enable = false;
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
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

  # Enable SSH via macOS Remote Login (sshd)
  services.openssh = {
    enable = true;
  };

  # Tailscale mesh VPN with SSH access
  services.tailscale = {
    enable = true;
  };

  # Cachix auth token for pushing to jedimaster cache
  age.secrets.cachix-token.file = ../../secrets/cachix-token.age;

  # Kanata key remapper (cross-platform, migrated from keyd)
  services.kanata-remapper = {
    enable = true;
    # Uses shared kanata.kbd config by default (CapsLock→Esc/Ctrl, vim mode, etc.)
  };

  # Rawtalk QMK Layer Switcher Service
  services.rawtalk = {
    enable = true;
  };

  # Emacs daemon service
  services.emacs-daemon = {
    enable = false;
    package = pkgs.emacs;
    socketActivation = false;
  };

  system = {
    primaryUser = "morph";
    defaults = {
      NSGlobalDomain = {
        KeyRepeat = 1;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticWindowAnimationsEnabled = false;
        NSWindowResizeTime = 0.001;
      };
      dock = {
        autohide = true;
        orientation = "bottom";
        showhidden = true;
        tilesize = 40;
        launchanim = false;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.0;
        expose-animation-duration = 0.1;
      };
      finder = {
        QuitMenuItem = false;
        AppleShowAllExtensions = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        FXPreferredViewStyle = "Nlsv";
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        _FXSortFoldersFirst = true;
      };
      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
      };
      spaces = {
        spans-displays = true;
      };
    };
    keyboard = {
      enableKeyMapping = true;
    };

    activationScripts.postActivation.text = ''
      sudo -u morph bash -c '
        defaults write com.apple.finder FXPreferredGroupBy -string "Date Modified"
        find ~/Documents ~/Downloads ~/Desktop -name ".DS_Store" -depth -exec rm {} \; 2>/dev/null || true
        killall Finder 2>/dev/null || true
      '

      # Kanata on macOS requires the Karabiner-VirtualHIDDevice driver.
      # After first install of karabiner-elements cask, you must:
      #   1. Open Karabiner-Elements and follow the prompts to allow the system extension
      #      (System Settings -> Privacy & Security -> allow "Karabiner-Elements.app")
      #   2. Disable all Karabiner remapping rules so it only acts as a driver for kanata
      #      (Karabiner-Elements -> Simple Modifications -> leave empty)
      #   3. Restart the kanata daemon: sudo launchctl kickstart -k system/org.kanata.daemon
    '';

    stateVersion = 4;
  };
}
