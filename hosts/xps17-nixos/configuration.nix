{
  config,
  current,
  lib,
  pkgs,
  home-manager,
  ...
}: let
  keydConfig = ''
    [ids]
    *

    [main]

    capslock = overload(ctrl_vim, esc)

    # ctrl_vim modifier layer; inherits from 'Ctrl' modifier layer

    [ctrl_vim:C]

    space = swap(vim_mode)

    # vim_mode modifier layer; also inherits from 'Ctrl' modifier layer

    [vim_mode:C]

    h = left
    j = down
    k = up
    l = right
    # forward word
    w = C-right
    # backward word
    b = C-left
  '';
in {
  imports = [
    <nixos-hardware/dell/xps/17-9710/intel>
    ./hardware-configuration.nix
    ./picom.nix
    ./dslr.nix
    # ./keyd.nix
    # ./forticlientsslvpn.nix
    # ./mongosh.nix
    # ./wireguard.nix
  ];

  # Bootloader.
  boot = {
    kernelParams = ["nohibernate"];
    initrd = {
      availableKernelModules = ["xhci_pci" "nvme" "usbhid" "uas" "sd_mod" "rtsx_pci_sdmmc"];
      kernelModules = [];
    };
    kernelModules = ["kvm-intel" "wireguard"];
    extraModulePackages = [];
    supportedFilesystems = ["ntfs"];
    loader = {
      systemd-boot.enable = false;
      grub = {
        version = 2;
        enable = true;
        devices = ["nodev"];
        efiSupport = true;
        useOSProber = true;
      };

      efi = {
        efiSysMountPoint = "/boot/efi";
        canTouchEfiVariables = true;
      };
    };
  };

  # networking
  networking.hostName = "xps17-nixos";
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
        ExecStart = "${pkgs.nur.repos.foolnotion.keyd}/bin/keyd";
      };
      # wantedBy = ["sysinit.target"];
    };

    # [Unit]
    # Description=key remapping daemon
    # Requires=local-fs.target
    # After=local-fs.target
    #
    # [Service]
    # Type=simple
    # ExecStart=/usr/bin/keyd
    #
    # [Install]
    # WantedBy=sysinit.target

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
  };
  environment.etc."keyd/default.conf".text = keydConfig;

  # locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.utf8";

  # Enable sound with pipewire.
  # hardware.bluetooth.enable = true;

  hardware.bluetooth = {
    enable = true;
    # hsphfpd.enable = true; # HSP & HFP daemon
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
    extraGroups = ["uucp" "dialout" "networkmanager" "wheel" "docker" "video" "vboxusers" "libvirtd" "input" "adbusers" "wireshark"];
    # packages = with pkgs; [ ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      nur =
        (import (
          builtins.fetchTarball {
            url = "https://github.com/nix-community/NUR/archive/master.tar.gz";
            sha256 = "0sc9b9iicllz0kfd8sy7zx8r2dbp4sz42accm3j2lylqypyn42zj";
          }
        ))
        {
          inherit pkgs;
        };
    };

    # insecure package needed for nixops
    permittedInsecurePackages = [
      "python2.7-pyjwt-1.7.1"
    ];
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

    # samba = {
    #   enable = true;
    #   shares = {
    #     public = {
    #       path = "/home/morp/Public";
    #       "read only" = true;
    #       browseable = "yes";
    #       "guest ok" = "yes";
    #       comment = "Public samba share.";
    #     };
    #   };
    # };

    xserver = {
      # Enable touchpad support (enabled default in most desktopManager).
      libinput.enable = true;

      # Enable the X11 windowing system.
      enable = true;

      # Configure keymap in X11
      layout = "us";
      xkbVariant = "";

      desktopManager = {
        xterm = {
          enable = false;
        };
        mate = {
          enable = true;
        };
        gnome = {
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

    virtualbox = {
      host.package = pkgs.virtualbox;
      host.headless = false;
      host.enable = true;
      host.enableWebService = true;
      host.enableExtensionPack = true;
      guest.enable = true;
      guest.x11 = true;
    };
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
  };

  system.stateVersion = "22.05";

  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };
    optimise.automatic = true;
  };

  # tailscale
  # enable the tailscale service
  services.tailscale.enable = true;

  # create a oneshot job to authenticate to Tailscale
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = ["network-pre.target" "tailscale.service"];
    wants = ["network-pre.target" "tailscale.service"];
    wantedBy = ["multi-user.target"];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up -authkey tskey-auth-kX3axB1CNTRL-fSTtKA9DYwVqHdTQdBUb1W9EYVPcp6Bv
    '';
  };

  networking.firewall = {
    # warning: Strict reverse path filtering breaks Tailscale
    # exit node use and some subnet routing setups.
    checkReversePath = "loose";
    # enable the firewall
    enable = true;

    # always allow traffic from your Tailscale network
    trustedInterfaces = ["tailscale0"];

    # allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [config.services.tailscale.port];

    # allow you to SSH in over the public internet
    allowedTCPPorts = [22];
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
      polybar
      gnumake
      clipmenu
      playerctl
      xorg.xbacklight
      autorandr
      xdotool
      shared-mime-info
      xdg-user-dirs
      bluedevil
      plasma5Packages.kdeconnect-kde
      pciutils
      usbutils
      ventoy-bin
      picom
      bluez
      rustup
      brightnessctl
      xdragon
      nur.repos.foolnotion.keyd
      # nur.repos.meain.kmonad
      gnome.dconf-editor
      mate.mate-power-manager
      mate.mate-media
      orchis-theme
      tela-circle-icon-theme
      docker
      libreoffice
      reptyr # TODO learn usuage
      wireshark
      tshark
      perf-tools
      procps
      zsync
      cdrkit
      sqlitebrowser
      # nfs-utils
      zfs
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
      # openconnect
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
      mycli
      grc
      cmake
      ninja
      clang
      yarn
      firefox
      mongodb
      android-studio
      android-tools
      android-udev-rules
      gradle
      zoom-us
      # teams
      ffmpeg-full
      awscli
      vim
      vscode
      # TODO change to wireguard kernel_module
      wireguard-tools
      virtualbox
      tailscale
      nixops
    ];
  };
}
