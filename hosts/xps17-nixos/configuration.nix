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
    ./tailscale.nix
    ./syncthing.nix
    # ./dslr.nix
    # ./hyprland.nix
    # ./b2-backup.nix
  ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = true;

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

  services = {
    xserver = {
      libinput.enable = true;
      enable = true;

      layout = "us";
      xkbVariant = "";
      desktopManager = {
        # xterm = {
        #   enable = true;
        # };
        mate = {
          enable = true;
          # excludePackages = [ pkgs.mate.mate-terminal pkgs.mate.pluma ];
        };
        # gnome = {
        #   enable = true;
        # };
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

    emacs.package = pkgs.emacs-unstable;

    # printing
    printing.enable = true;
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

    # adb.enable = true;
    # dconf = {
    #   enable = true;
    # };
    # kdeconnect = {
    #   enable = true;
    # };

    mtr = {
      enable = true;
    };
    autojump = {
      enable = true;
    };
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
  system.stateVersion = "23.05"; # Did you read the comment?
  # system.stateVersion = config.system.nixos.release;

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
    # clipmenu
    # playerctl
    xorg.xbacklight
    autorandr
    xdotool
    xdg-user-dirs
    bluedevil
    # plasma5Packages.kdeconnect-kde
    pciutils
    usbutils
    ventoy-bin
    bluez
    rustup
    rustc
    brightnessctl
    xdragon
    keyd
    # ms-edge
    gnome.dconf-editor
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
    # zfs
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
    discord
    # mycli
    grc
    cmake
    ninja
    clang
    yarn
    firefox
    # mongodb
    # zoom-us
    # teams
    ffmpeg-full
    vim
    wireguard-tools
    libtool
    libvterm
    # virtualbox
    # tailscale
    # nixops
    os-prober
    kitty
    android-tools
    # android-studio
    android-udev-rules
    age
    rage
    uxplay
    arandr
    libclang
    libstdcxx5
    ctags
    zsh-completions

    # vpn
    # openconnect_openssl
    networkmanager
    networkmanagerapplet

    # backup
    # borgbackup
    # borgmatic

    # gaming
    # chiaki
    # avrlibc
    # conda

    # i3 rice
    # polybar
    # viu
    # ueberzug
    dmenu
    # gimp
    avahi
    # zotero
    # hledger
    # tio
    # slack
    # exa
    eza

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
