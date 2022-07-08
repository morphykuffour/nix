{ config, current, lib, pkgs, ... }:

# ${getEnv "HOME"}
{
  imports =
    [
      ./hardware-configuration.nix
      ./picom.nix
    ];

  # editor settings TODO combine home-manager and linux system
  environment.variables.EDITOR = "nvim";


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
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # networking
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  
  networking.networkmanager.enable = true;

  networking.firewall = {
    allowedTCPPorts = [ 17500 ];
    allowedUDPPorts = [ 17500 ];
  };

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

  ## HACK: the provided service uses a dynamic user which can not authenticate to the pulse daemon
  ## This is mitigated by using a static user
  #users.users.spotifyd = {
  #  group = "audio";
  #  extraGroups = [ "audio" ];
  #  description = "spotifyd daemon user";
  #  home = "/var/lib/spotifyd";
  #};

  #systemd.services.spotifyd = {
  #  serviceConfig.User = "spotifyd";

  #  serviceConfig.DynamicUser = lib.mkForce false;
  #  serviceConfig.SupplementaryGroups = lib.mkForce [ ];
  #};
  ## End of hack...

  systemd.services.keyd = {
    enable = true;
    description = "key remapping daemon";
    unitConfig = {
      Requires = "local-fs.target";
      After = "local-fs.target";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.nur.repos.foolnotion.keyd}/bin/keyd";
    };
    wantedBy = [ "sysinit.target" ];
  };


  # locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.utf8";


  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;


  # user account
  users.defaultUserShell = pkgs.zsh;
  users.users.morp = {
    isNormalUser = true;
    description = "morp";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "vboxusers" ];
    packages = with pkgs; [
      vim
      vscode
      sublime
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # nixpkgs.config.packageOverrides = pkgs: {
  #   nur = import
  #     (builtins.fetchTarball
  #       {
  #         url = "https://github.com/nix-community/NUR/archive/master.tar.gz";
  #         sha256 = "12jfm3qqhxa418c4s867qwqz46gxhh3wb5vym954d2sli0yxnnv3";
  #       })
  #     {
  #       inherit pkgs;

  #     };
  # };

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
    polybar
    gnumake
    clipmenu
    playerctl
    xorg.xbacklight
    dropbox-cli
    # xdg-utils
    # xdg-desktop-portal
    bluedevil
    kdeconnect
    pciutils
    usbutils
    bottles
    # flatpak
    picom
    bluez
    logiops
    brightnessctl

    # keyboard remapping stuff
    nur.repos.foolnotion.keyd

    # container stuff
    docker
    docker-compose
    containerd
    cni-plugins
    ignite
    runc

    # tools
    perf-tools # TODO mount debugfs
    procps
    zsync
    cdrkit

    # vm stuff
    vagrant
    virtualbox
    firecracker
    qemu
    libvirt
    virt-manager
    spice-gtk
    quickemu
    xdg-user-dirs
    samba
    OVMF
    swtpm
  ];

  # TODO move services under one function
  services = {
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

    openssh.enable = true;
    clipmenu.enable = true;
    blueman.enable = true;
    # Enable CUPS to print documents.
    printing.enable = true;
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
        xfce = {
          enable = true;
          noDesktop = true;
          enableXfwm = false;
        };
        # Enable the gnome Desktop Environment.
        # gnome.enable = true;

        # Enable the mate Desktop Environment.
        # mate.enable = true;

        # Enable the KDE Plasma Desktop Environment.
        # plasma5.enable = true;
      };

      displayManager = {
        # i3 display manager
        defaultSession = "none+i3";
        autoLogin = {
          # Login
          enable = false;
          user = "morp";
        };

        # kde display manager
        sddm.enable = true;

        # gnome display manager
        # gdm.enable = true;
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

  # virtualisation
  virtualisation = {

    docker = {
      enable = true;
    };

    virtualbox = {
      guest.enable = true;
      host.enableExtensionPack = true;
      host.enable = true;
    };

    libvirtd = {
      enable = true;
      qemu = {
        runAsRoot = false;
        ovmf = {
          enable = true;
          package = pkgs.OVMFFull;
        };
        swtpm.enable = true;
      };
    };
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

  # xdg.portal.enable = true;
  # xdg.portal.gtkUsePortal = true;
  environment.pathsToLink = [ "/libexec" ];
  system.stateVersion = "22.05";

  #temporary bluetooth fix
  systemd.tmpfiles.rules = [
    "d /var/lib/bluetooth 700 root root - -"
  ];
  systemd.targets."bluetooth".after = [ "systemd-tmpfiles-setup.service" ];

  # use flakes
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
  };
}
