{ config, current, lib, pkgs, home-manager, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./picom.nix
      ./zfs.nix
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
  # boot.loader.systemd-boot.enable = true;
  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "uas" "sd_mod" "rtsx_pci_sdmmc" ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    supportedFilesystems = [ "ntfs" ];
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
    wantedBy = [ "graphical-session.target" ];
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

  systemd.services = {
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

    kmonad = {
      enable = false;
      unitConfig = {
        description = "kmonad key remapping daemon";
      };
      serviceConfig = {
        Restart = "always";
        RestartSec = "3";
        ExecStart = "${pkgs.nur.repos.meain.kmonad}/bin/kmonad ./keeb/colemak-dh-extend-ansi.kbd";
        Nice = "-20";
      };
      wantedBy = [ "default.target" ];
    };
  };


  # locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.utf8";

  # Enable sound with pipewire.
  hardware.bluetooth.enable = true;
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;


  # user account
  users.defaultUserShell = pkgs.zsh;
  users.users.morp = {
    isNormalUser = true;
    description = "default account for linux";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "vboxusers" "libvirtd" ];
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
      nur = (import (builtins.fetchTarball {
        url = "https://github.com/nix-community/NUR/archive/master.tar.gz";
        sha256 = "1dd5r1bqnd4m141cnjvkdk6isl14hdf0rv98bw1p9hcl8w4ff4cg";
      }
      )) {
        inherit pkgs;
      };
    };
  };




  # TODO move services under one function
  services = {

    qemuGuest.enable = true;
    # nfs TODO fix for vagrant
    nfs.server = {
      enable = true;
      lockdPort = 4001;
      mountdPort = 4002;
      statdPort = 4000;
      exports = ''
        /export         192.168.1.10(rw,fsid=0,no_subtree_check) 192.168.1.15(rw,fsid=0,no_subtree_check)
        /export/Samsung_PSSD_T7 192.168.1.10(rw,nohide,insecure,no_subtree_check) 192.168.1.15(rw,nohide,insecure,no_subtree_check)
      '';

      extraNfsdConfig = '''';
    };

    udev.packages = [
      pkgs.qmk-udev-rules
    ];

    spotifyd = {
      enable = true;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };

    httpd = {
      enable = true;
      package = pkgs.apacheHttpd;
      user = "wwwrun";
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

    # flatpak.enable = true;

    samba = {
      enable = true;
      shares = {
        public =
          {
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
        # xfce = {
        #   enable = true;
        #   noDesktop = true;
        #   enableXfwm = false;
        # };
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

  # enable xdg_data_dirs
  # targets.genericLinux.enable = true;

  virtualisation = {
    # qemu.package = pkgs.qemu;

    spiceUSBRedirection.enable = true;

    docker = {
      enable = true;
    };

    # virtualbox = {
    #   guest.enable = true;
    #   host.enable = true;
    #   host.headless = true;
    #   host.enableExtensionPack = true;
    #   host.enableWebService = true;
    #   host.addNetworkInterface = true;
    # };


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
      allowedBridges = [ "virbr0" "virbr1" ];
    };
  };

  # Minimal configuration for NFS support with Vagrant.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 17500 111 2049 4000 4001 4002 20048 ];
    allowedUDPPorts = [ 17500 111 2049 4000 4001 4002 20048 ];

    extraCommands = ''
      ip46tables -I INPUT 1 -i vboxnet+ -p tcp -m tcp --dport 2049 -j ACCEPT
    '';
  };

  # fonts
  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
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

  environment.pathsToLink = [ "/libexec" ];
  system.stateVersion = "22.05";

  # use flakes
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
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
    polybar
    gnumake
    clipmenu
    playerctl
    xorg.xbacklight
    dropbox-cli
    i3-resurrect
    autorandr
    xdotool
    plover.dev
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
    nur.repos.meain.kmonad
    gnome.dconf-editor
    docker
    libreoffice
    reptyr
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
    swtpm
  ];
}
