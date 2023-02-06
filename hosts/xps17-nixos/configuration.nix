{
  config,
  current,
  lib,
  pkgs,
  home-manager,
  agenix,
  ...
}: let
  # ms-edge = pkgs.callPackage ../../pkgs/ms-edge {};
  keyd = pkgs.callPackage ../../pkgs/keyd {};
  keydConfig = builtins.readFile ../../pkgs/keyd/keymaps.conf;
in {
  imports = [
    ./hardware-configuration.nix
    ./dslr.nix
  ];

  # system info
  system.stateVersion = config.system.nixos.release;

  # sudoless
  security.sudo.wheelNeedsPassword = false;

  # Bootloader.
  boot = {
    kernelParams = ["nohibernate"];
    initrd = {
      availableKernelModules = ["xhci_pci" "nvme" "usbhid" "uas" "sd_mod" "rtsx_pci_sdmmc"];
      kernelModules = [];
    };
    kernelModules = ["kvm-amd" "kvm-intel" "wireguard"];
    binfmt.emulatedSystems = ["aarch64-linux"];
    extraModulePackages = [];
    supportedFilesystems = ["ntfs"];
    loader = {
      systemd-boot.enable = false;
      grub = {
        version = 2;
        enable = true;
        devices = ["nodev"];
        efiSupport = true;
        useOSProber = false;
      };

      efi = {
        efiSysMountPoint = "/boot/efi";
        canTouchEfiVariables = true;
      };
    };
  };

  # systemd.user.services.dropbox = {
  #   description = "Dropbox";
  #   wantedBy = ["graphical-session.target"];
  #   environment = {
  #     QT_PLUGIN_PATH = "/run/current-system/sw/" + pkgs.qt5.qtbase.qtPluginPrefix;
  #     QML2_IMPORT_PATH = "/run/current-system/sw/" + pkgs.qt5.qtbase.qtQmlPrefix;
  #   };
  #   serviceConfig = {
  #     ExecStart = "${pkgs.dropbox.out}/bin/dropbox";
  #     ExecReload = "${pkgs.coreutils.out}/bin/kill -HUP $MAINPID";
  #     KillMode = "control-group"; # upstream recommends process
  #     Restart = "on-failure";
  #     PrivateTmp = true;
  #     ProtectSystem = "full";
  #     Nice = 10;
  #   };
  # };

  systemd.services = {
    keyd = {
      enable = true;
      description = "keyd key remapping daemon";
      unitConfig = {
        Requires = "local-fs.target";
        After = "local-fs.target";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.keyd}/bin/keyd";
      };
    };
  };

  environment.etc."keyd/default.conf".text = keydConfig;

  # wakeup from sleep permanently TODO: move to powerManagement.powerUpCommands
  # FIXME: wakeupScript
  # environment.etc."rc.local".text = wakeupScript;

  # locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.utf8";

  hardware.bluetooth = {
    enable = true;
    # hsphfpd.enable = true; # HSP & HFP daemon
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  security.rtkit.enable = true;

  # user account
  users.defaultUserShell = pkgs.bash;
  # users.users.root = {shell = pkgs.zsh;};
  users.users.morp = {
    isNormalUser = true;
    description = "default account for linux";
    shell = pkgs.zsh;
    extraGroups = ["uucp" "dialout" "networkmanager" "wheel" "docker" "audio" "video" "vboxusers" "libvirtd" "input" "adbusers" "wireshark"];
    # packages = with pkgs; [ ];
  };

  nix = {
    settings = {
      auto-optimise-store = true;
      sandbox = false;
      substituters = ["https://jedimaster.cachix.org"];
      trusted-users = ["root" "morp"];
      trusted-public-keys = [
        "jedimaster.cachix.org-1:d3z8VEyrrqcYEe/9wOhla6iXb4ArWUoQLB5tz1b+CZA="
      ];
    };
    # registry = {nixpkgs.flake = nixpkgs;};
  };

  nixpkgs = {
    # crossSystem.system = "aarch64-linux";
    # buildPlatform.system = "x86_64-linux";
    # hostPlatform.system = "aarch64-linux";
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;

      # insecure package needed for nixops
      permittedInsecurePackages = [
        "python2.7-pyjwt-1.7.1"
        "python2.7-certifi-2021.10.8"
      ];
    };
  };

  xdg.portal.enable = true;

  sound.enable = true;
  hardware.pulseaudio = {
    enable = false;
    # package = pkgs.pulseaudioFull;
  };

  services = {
    fwupd.enable = true;
    fprintd = {
      enable = true;
      # TODO
      # package = pkgs.callPackage ../../pkgs/fprintd {};
    };

    qemuGuest.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    mysql = {
      user = "morp";
      package = pkgs.mysql80;
      group = "wheel";
      enable = false;
    };
    longview.mysqlPasswordFile = "/run/keys/dbpassword";

    openssh.enable = true;
    clipmenu.enable = true;
    blueman.enable = true;

    # Enable CUPS to print documents.
    printing = {
      enable = true;
      drivers = [
        pkgs.cnijfilter2
      ];
    };

    avahi = {
      nssmdns = true;
      enable = true;
      publish = {
        enable = true;
        userServices = true;
        domain = true;
      };
      interfaces = ["wlp0s20f3" "tailscale0"];
    };

    flatpak.enable = true;

    xserver = {
      libinput.enable = true;
      enable = true;
      layout = "us";
      xkbVariant = "";
      desktopManager = {
        xterm = {
          enable = false;
        };
        mate = {
          enable = true;
        };
      };

      displayManager = {
        startx.enable = true;
        defaultSession = "mate";
        autoLogin = {
          enable = false;
          user = "morp";
        };
        sddm.enable = true;
      };

      # windowManager.i3 = {
      #   enable = true;
      #   package = pkgs.i3-gaps;

      #   # extraPackages = with pkgs; [
      #   #   # i3status
      #   #   # i3lock
      #   # ];
      # };
    };

    syncthing = {
      enable = true;
      dataDir = "/home/morp";
      openDefaultPorts = true;
      configDir = "/home/morp/.config/syncthing";
      user = "morp";
      group = "users";
      guiAddress = "127.0.0.1:8384";
      overrideDevices = true;
      overrideFolders = true;
      devices = {
        "xps17-nixos" = {id = "44LYB6O-ELZWVNP-5R576R3-MRD3MM2-FXORGWG-WRC26ZQ-JAMWKRS-5SCNUAY";};
        "rpi3b-ubuntu" = {id = "TTEQED5-YB5HDQQ-4OYRRUE-PQMO7XF-TWCNSQ7-4SFRM5X-N6C3IBY-ELN2XQV";};
        "macmini-darwin" = {id = "OK4365M-ZZC4CDT-A6W2YF2-MPIX3GR-FYZIWWJ-5QS6RYM-5KYU35K-SLYBHQO";};
        "workstation-windows" = {id = "OT562TI-J4NCYP6-7SCXJL6-PWDVBGX-EJA5G7S-3Q4G4TG-UR7RN3F-V3OVAAH";};
      };

      folders = {
        "Dropbox" = {
          path = "/home/morp/Dropbox";
          devices = ["xps17-nixos" "rpi3b-ubuntu" "macmini-darwin" "workstation-windows"];
          versioning = {
            type = "staggered";
            params = {
              cleanInterval = "3600";
              maxAge = "15768000";
            };
          };
        };

        "Org" = {
          path = "/home/morp/Org/";
          id = "prsu2-hrpwq";
          devices = ["xps17-nixos" "rpi3b-ubuntu" "macmini-darwin" "workstation-windows"];
          versioning = {
            type = "staggered";
            params = {
              cleanInterval = "3600";
              maxAge = "15768000";
            };
          };
        };

        "iCloud" = {
          path = "/home/morp/iCloud/";
          devices = ["xps17-nixos" "rpi3b-ubuntu" "macmini-darwin" "workstation-windows"];
          versioning = {
            type = "staggered";
            params = {
              cleanInterval = "3600";
              maxAge = "15768000";
            };
          };
        };
      };
    };
  };

  virtualisation = {
    spiceUSBRedirection.enable = true;

    docker = {
      enable = true;
    };

    libvirtd = {
      enable = true;
      qemu = {
        runAsRoot = true;
        ovmf = {
          enable = true;
        };
        swtpm.enable = true;
      };
      allowedBridges = ["virbr0" "virbr1"];
    };
  };

  fonts.fonts = with pkgs; [
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
  ];

  # Programs
  programs = {
    adb.enable = true;
    dconf = {
      enable = true;
    };
    kdeconnect = {
      enable = true;
    };
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

  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };
    optimise.automatic = true;
  };

  environment = {
    variables = {
      EDITOR = "nvim";
      TERMINAL = "kitty";
      BROWSER = "brave";
    };

    pathsToLink = ["/libexec"];
    sessionVariables = rec {
      XDG_CACHE_HOME = "\${HOME}/.cache";
      XDG_CONFIG_HOME = "\${HOME}/.config";
      XDG_BIN_HOME = "\${HOME}/.local/bin";
      XDG_DATA_HOME = "\${HOME}/.local/share";
      ANDROID_HOME = "\${HOME}/Android/Sdk";
      CHROME_EXECUTABLE = "/home/morp/.nix-profile/bin/google-chrome-stable";
      PATH = [
        "\${XDG_BIN_HOME}"
      ];
    };

    systemPackages = with pkgs; [
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
      clipmenu
      playerctl
      xorg.xbacklight
      autorandr
      xdotool
      xdg-user-dirs
      bluedevil
      plasma5Packages.kdeconnect-kde
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
      reptyr
      wireshark
      tshark
      procps
      zsync
      cdrkit
      sqlitebrowser
      # zfs
      bashmount
      vagrant
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
      mysql80
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
      vscode
      wireguard-tools
      libtool
      libvterm
      # virtualbox
      tailscale
      # nixops
      # os-prober
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
      borgbackup
      borgmatic

      # gaming
      chiaki
      # avrlibc
      # conda

      # i3 rice
      # polybar
      viu
      ueberzug
      dmenu
      gimp
      avahi
      # R packages for data science
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
          llr
          tidyverse
          devtools
          bookdown
          VennDiagram
        ];
      })
    ];
  };
}
