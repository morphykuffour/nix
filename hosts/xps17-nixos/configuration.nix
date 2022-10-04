{
  config,
  current,
  lib,
  pkgs,
  home-manager,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./picom.nix
    ./zfs.nix
    ./dslr.nix
  ];

  environment.variables.EDITOR = "vim";

  environment.sessionVariables = rec {
    XDG_CACHE_HOME = "\${HOME}/.cache";
    XDG_CONFIG_HOME = "\${HOME}/.config";
    XDG_BIN_HOME = "\${HOME}/.local/bin";
    XDG_DATA_HOME = "\${HOME}/.local/share";

    PATH = [
      "\${XDG_BIN_HOME}"
    ];
  };

  # Bootloader.
  boot = {
    initrd = {
      availableKernelModules = ["xhci_pci" "nvme" "usbhid" "uas" "sd_mod" "rtsx_pci_sdmmc"];
      kernelModules = [];
    };
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
    supportedFilesystems = ["ntfs"];
    loader = {
      systemd-boot.enable = false;
      grub = {
        version = 2;
        enable = true;
        devices = [
          "nodev"
          # "/dev/nvme1n1"
        ];
        efiSupport = true;
        #   efiInstallAsRemovable = true;
        useOSProber = true;
      };

      efi = {
        efiSysMountPoint = "/boot/efi";
        canTouchEfiVariables = true;
      };
    };
  };

  # networking
  networking.hostName = "xps17-nixos"; # Define your hostname.
  # networking.wireless.enable = true;
  networking.networkmanager.enable = true;

  systemd.user.services.dropbox = {
    description = "Dropbox";
    wantedBy = ["graphical-session.target"];
    environment = {
      QT_PLUGIN_PATH = "/run/current-system/sw/" + pkgs.qt5.qtbase.qtPluginPrefix;
      QML2_IMPORT_PATH = "/run/current-system/sw/" + pkgs.qt5.qtbase.qtQmlPrefix;
    };
    serviceConfig = {
      ExecStart = "${pkgs.dropbox.out}/bin/dropbox";
      ExecReload = "${pkgs.coreutils.out}/bin/kill -HUP $MAINPID";
      KillMode = "control-group"; # upstream recommends process
      Restart = "on-failure";
      PrivateTmp = true;
      ProtectSystem = "full";
      Nice = 10;
    };
  };

  # systemd.services = {
  # keyd = {
  #   enable = false;
  #   description = "keyd key remapping daemon";
  #   unitConfig = {
  #     Requires = "local-fs.target";
  #     After = "local-fs.target";
  #   };
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = "${pkgs.nur.repos.foolnotion.keyd}/bin/keyd";
  #   };
  #   wantedBy = [ "sysinit.target" ];
  # };

  # kmonad = {
  #   enable = false;
  #   unitConfig = {
  #     description = "kmonad key remapping daemon";
  #   };
  #   serviceConfig = {
  #     Restart = "always";
  #     RestartSec = "3";
  #     ExecStart = "${pkgs.nur.repos.meain.kmonad}/bin/kmonad ./keeb/colemak-dh-extend-ansi.kbd";
  #     Nice = "-20";
  #   };
  #   wantedBy = [ "default.target" ];
  # };
  # };

  # locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.utf8";

  # Enable sound with pipewire.
  # hardware.bluetooth.enable = true;

  hardware.bluetooth = {
    enable = true;
    hsphfpd.enable = true; # HSP & HFP daemon
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # user account
  users.defaultUserShell = pkgs.zsh;
  users.users.morp = {
    isNormalUser = true;
    description = "default account for linux";
    shell = pkgs.zsh;
    extraGroups = ["uucp" "dialout" "networkmanager" "wheel" "docker" "video" "vboxusers" "libvirtd" "input"];
    packages = with pkgs; [
      vim
      vscode
      sublime
    ];
  };

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;

    permittedInsecurePackages = [
      "python3.10-mistune-0.8.4"
    ];

    packageOverrides = pkgs: {
      nur =
        (import (
          builtins.fetchTarball {
            url = "https://github.com/nix-community/NUR/archive/master.tar.gz";
            sha256 = "1jdaq4py6556qvdd83v29clx1w9p144zmp0nz9h9fmzzv15ii778";
          }
        ))
        # ;
        #
        # discord = (import (builtins.fetchTarball {
        #   url = "https://github.com/InternetUnexplorer/discord-overlay/archive/main.tar.gz";
        #   sha256 = "0gwlgjijqr23w2g2pnif8dz0a8df4jv88hga0am3c6cch4h4s05m";
        # }))
        #
        {
          inherit pkgs;
        };
    };
  };

  xdg.portal.enable = true;
  services = {
    fwupd.enable = true;
    fprintd.enable = true;

    qemuGuest.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    mysql = {
      enable = true;
      package = pkgs.mysql80;
    };

    httpd = {
      enable = true;
      package = pkgs.apacheHttpd;
      adminAddr = "morty@example.org";
      user = "morp";
      # extraConfig =
      # ''
      #   Listen 127.0.0.1:80
      #   ServerName localhost
      # '';
    };

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
      enable = true;
      nssmdns = true;
    };

    flatpak.enable = true;

    samba = {
      enable = true;
      shares = {
        public = {
          path = "/home/morp/Public";
          "read only" = true;
          browseable = "yes";
          "guest ok" = "yes";
          comment = "Public samba share.";
        };
      };
    };

    xserver = {
      # Enable touchpad support (enabled default in most desktopManager).
      libinput.enable = true;

      # nvidia gpu config
      # videoDrivers = [ "nvidia" ];

      # Enable the X11 windowing system.
      enable = true;

      # Configure keymap in X11
      layout = "us";
      xkbVariant = "";

      desktopManager = {
        xterm.enable = false;
        xfce = {
          enable = true;
          # noDesktop = true;
          # enableXfwm = false;
        };
        mate = {
          enable = true;
          # excludePackages = [ pkgs.mate.mate-terminal pkgs.mate.pluma ];
        };
      };

      displayManager = {
        defaultSession = "none+i3";
        autoLogin = {
          enable = false;
          user = "morp";
        };

        # kde display manager
        sddm.enable = true;
      };

      windowManager.i3 = {
        enable = true;
        package = pkgs.i3-gaps;

        extraPackages = with pkgs; [
          dmenu
          i3status
          i3lock
          sxhkd
        ];
      };
    };
  };

  virtualisation = {
    # qemu.package = pkgs.qemu;

    spiceUSBRedirection.enable = true;

    docker = {
      enable = true;
    };

    # fix flake build TODO
    libvirtd = {
      enable = true;
      qemu = {
        runAsRoot = true;
        ovmf = {
          enable = true;
          # package = [ pkgs.OVMFFull ];
        };
        swtpm.enable = true;
      };
      allowedBridges = ["virbr0" "virbr1"];
    };
  };

  # Minimal configuration for NFS support with Vagrant.
  # networking.firewall = {
  #   enable = true;
  #   allowedTCPPorts = [ 17500 111 2049 4000 4001 4002 20048 ];
  #   allowedUDPPorts = [ 17500 111 2049 4000 4001 4002 20048 ];
  #
  #   extraCommands = ''
  #     ip46tables -I INPUT 1 -i vboxnet+ -p tcp -m tcp --dport 2049 -j ACCEPT
  #   '';
  # };

  # fonts
  fonts.fonts = with pkgs; [
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
  ];

  # Programs
  programs = {
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
  };

  environment.pathsToLink = ["/libexec"];
  system.stateVersion = "22.05";

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };
    optimise.automatic = true;
  };

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
    # polybar
    gnumake
    clipmenu
    playerctl
    xorg.xbacklight
    dropbox-cli
    # i3-resurrect
    autorandr
    xdotool
    # plover.dev
    # plover.stable
    # plover
    shared-mime-info
    xdg-user-dirs
    bluedevil
    kdeconnect
    pciutils
    usbutils
    libusb1
    ventoy-bin
    picom
    bluez
    logiops
    rustup
    brightnessctl
    xdragon
    keymapviz
    vial
    hidapi
    # nur.repos.foolnotion.keyd
    # nur.repos.meain.kmonad
    gnome.dconf-editor
    mate.mate-power-manager
    orchis-theme
    tela-circle-icon-theme
    docker
    libreoffice
    reptyr
    wireshark
    tshark
    rustdesk
    perf-tools
    procps
    zsync
    cdrkit
    sqlitebrowser
    nfs-utils
    zfs
    bashmount
    apacheHttpd
    vagrant
    grub2
    qemu
    libvirt
    virt-manager
    spice-gtk
    quickemu
    samba
    OVMF
    openconnect
    swtpm
    gdb
    libinput-gestures
    wmctrl
    fprintd
    fwupd
    mysql80
    dbeaver
    dig
    psmisc
    discord
    neovim
    # mysql-workbench
  ];
}
