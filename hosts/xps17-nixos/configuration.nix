{
  inputs,
  config,
  current,
  lib,
  pkgs,
  home-manager,
  agenix,
  user,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./keyd.nix
    # ./tailscale.nix
    ./syncthing.nix
    # ./dslr.nix
    # ./hyprland.nix
    # ./b2-backup.nix
  ];

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.efiSupport = true;

  networking.hostName = "xps17-nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };
    optimise.automatic = true;
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };
  services = {
    emacs = {
      # package = pkgs.emacs-unstable;
      # package = pkgs.emacs-git;
      package = pkgs.emacs;
      enable = true;
      install = true;
    };

    blueman.enable = true;

    xserver = {
      libinput.enable = true;
      enable = true;

      layout = "us";
      xkbVariant = "";
      desktopManager = {
        # xterm = {
        #   enable = true;
        # };
        plasma5 = {
          enable = true;
        };
        mate = {
          enable = true;
          # excludePackages = [ pkgs.mate.mate-terminal pkgs.mate.pluma ];
        };
      };

      displayManager = {
        startx.enable = false;
        # sddm = {
        #   enable = true;
        # };
        gdm = {
          enable = true;
          wayland = false;
        };
        autoLogin = {
          enable = false;
          user = "morph";
        };
      };

      windowManager = {
        i3 = {
          enable = true;
          package = pkgs.i3-gaps;
        };
      };
    };

    # printing.enable = true;

    avahi = {
      nssmdns = true;
      enable = true;
      openFirewall = true;
      publish = {
        enable = true;
        userServices = true;
        domain = true;
      };
      allowInterfaces = ["wlp0s20f3" "tailscale0"];
    };
  };

  users.users.morph = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "Morphy Kuffour";
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [];
  };

  programs = {
    # obs-studio = {
    #   enable = true;
    #   plugins = with pkgs; [ obs-studio-plugins.wlrobs ];
    # };

    waybar.enable = true;
    zsh.enable = true;
    mtr.enable = true;
    autojump.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
  };
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system = {
    # stateVersion = config.system.nixos.release;
    stateVersion = "23.05"; # Did you read the comment?
    autoUpgrade = {
      enable = true;
      allowReboot = true;
    };
  };

  # sudoless
  # security.sudo.wheelNeedsPassword = false;

  environment.interactiveShellInit = ''
    alias c99='gcc'
  '';

  environment.systemPackages = with pkgs; [
    wget
    xclip
    git
    stow
    brave
    sqlite
    unzip
    coreutils
    binutils
    gcc
    flameshot
    sxiv
    gnumake
    xorg.xbacklight
    autorandr
    xdotool
    xdg-user-dirs
    pciutils
    usbutils
    ventoy-bin
    rustup
    rustc
    brightnessctl
    xdragon
    keyd
    # gnome.dconf-editor
    mate.mate-power-manager
    mate.mate-media
    orchis-theme
    tela-circle-icon-theme
    docker
    libreoffice
    # reptyr
    wireshark
    tshark
    procps
    zsync
    cdrkit
    sqlitebrowser
    bashmount
    # vagrant
    grub2
    qemu
    libvirt
    virt-manager
    spice-gtk
    quickemu
    samba
    OVMF
    gdb
    libinput-gestures
    wmctrl
    fwupd
    # mysql80
    dbeaver
    dig
    psmisc
    # discord
    # mycli
    grc
    cmake
    ninja
    clang
    yarn
    firefox
    ffmpeg-full
    vim
    wireguard-tools
    libtool
    libvterm
    os-prober
    kitty
    age
    rage
    uxplay
    arandr
    libclang
    libstdcxx5
    ctags
    zsh-completions
    networkmanager
    networkmanagerapplet
    dmenu
    avahi
    eza
    discord
    # mullvad

    # R packages for data science
    rstudio
    (pkgs.rWrapper.override {
      packages = with pkgs.rPackages; let
        llr = buildRPackage {
          name = "llr";
          src = pkgs.fetchFromGitHub {
            owner = "dirkschumacher";
            repo = "llr";
            rev = "0a654d469af231e9017e1100f00df47bae212b2c";
            sha256 = "0ks96m35z73nf2sb1cb8d7dv8hq8dcmxxhc61dnllrwxqq9m36lr";
          };
          propagatedBuildInputs = [rlang knitr reticulate];
          nativeBuildInputs = [rlang knitr reticulate];
        };
      in [
        knitr
        rlang
        # llr
        reticulate
        tidyverse
        devtools
        bookdown
        VennDiagram
        DiagrammeR
        webshot
        networkD3
        knitcitations
      ];
    })
  ];
}
