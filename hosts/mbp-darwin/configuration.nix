{
  config,
  pkgs,
  morph-emacs,
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
      gh
      fzf
      eza
      btop
      dog
      duf
      dust
      tokei
      delta
      (pkgs.writeShellScriptBin "emacs" ''
        # Connect to existing Emacs instance or start new frame
        if pgrep -f "emacs.*no-splash" > /dev/null; then
          # Emacs is running, create new frame
          ${morph-emacs.packages.aarch64-darwin.default}/bin/emacsclient -c "$@"
        else
          # Emacs not running, start it
          exec ${morph-emacs.packages.aarch64-darwin.default}/bin/emacs --no-splash "$@"
        fi
      '')
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
    taps = [];
    onActivation = {
      autoUpdate = false;
      cleanup = "none";
      upgrade = false;
    };
    brews = [
      "yabai"
    ];
    casks = [];
  };

  nix = {
    package = pkgs.nix;
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

  # Atomic Chrome service
  services.atomic-chrome = {
    enable = true;
    emacsPackage = morph-emacs.packages.aarch64-darwin.default;
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
        autohide = false;
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
    '';

    stateVersion = 4;
  };
}
