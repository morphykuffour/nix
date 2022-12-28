{
  config,
  current,
  lib,
  pkgs,
  home-manager,
  agenix,
  ...
}: let
  keyd = pkgs.callPackage ../../pkgs/keyd {};
  keydConfig = ''
    [ids]
    *

    [main]

    # remaps all modifiers to 'oneshot' keys
    # shift = oneshot(shift)
    # meta = oneshot(meta)
    # control = oneshot(control)
    # leftalt = oneshot(alt)
    # rightalt = oneshot(altgr)

    # paste with insert
    insert = S-insert

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
  # wakeupScript = ''
  #   echo enabled |sudo tee /sys/bus/usb/devices/*/power/wakeup
  # '';
  # wakeup = ''
  #
  #   for i in `/bin/grep USB /proc/acpi/wakeup | /usr/bin/awk '{print $1}'`;
  #   do
  #       echo $i > /proc/acpi/wakeup;
  #   done
  # '';
in {
  imports = [
    # <nixos-hardware/dell/xps/17-9700/intel>
    # <nixos-hardware/dell/xps/17-9700/nvidia>
    ./hardware-configuration.nix
    ./dslr.nix
    # agenix.nixosModule
    # ../../pkgs/keyd/default.nix
    # ./forticlientsslvpn.nix
    # ./mongosh.nix
    # ./wireguard.nix
  ];

  # nixpkgs.overlays = [ ];

  # system info
  system.stateVersion = config.system.nixos.release;

  # Bootloader.
  boot = {
    kernelParams = ["nohibernate"];
    initrd = {
      availableKernelModules = ["xhci_pci" "nvme" "usbhid" "uas" "sd_mod" "rtsx_pci_sdmmc"];
      kernelModules = [];
    };
    kernelModules = ["kvm-amd" "kvm-intel" "wireguard"];
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
  users.defaultUserShell = pkgs.bash;
  # users.users.root = {shell = pkgs.zsh;};
  users.users.morp = {
    isNormalUser = true;
    description = "default account for linux";
    shell = pkgs.zsh;
    extraGroups = ["uucp" "dialout" "networkmanager" "wheel" "docker" "video" "vboxusers" "libvirtd" "input" "adbusers" "wireshark"];
    # packages = with pkgs; [ ];
  };

  nix.settings.trusted-users = ["root" "morp"];
  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
    # packageOverrides = pkgs: {
    #   nur =
    #     (import (
    #       builtins.fetchTarball {
    #         url = "https://github.com/nix-community/NUR/archive/master.tar.gz";
    #         sha256 = "0d0xz5hv1b0cnvj0dx9l6pd0v3nf3npiqqq0136b0radbxn4i4h0";
    #       }
    #     ))
    #     {
    #       inherit pkgs;
    #     };
    # };

    # insecure package needed for nixops
    permittedInsecurePackages = [
      "python2.7-pyjwt-1.7.1"
      "python2.7-certifi-2021.10.8"
    ];
  };

  xdg.portal.enable = true;
  services = {
    fwupd.enable = true;
    fprintd = {
      enable = true;
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

    emacs = {
      enable = true;
      package = pkgs.emacs;
      install = true;
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
      reflector = true;
      interfaces = ["wlp0s20f3"];
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

        # https://unix.stackexchange.com/questions/445048/configure-xfce-startup-commands-in-nixos
        # session = [
        #   # {
        #   #   name = "play-with-mpv";
        #   #   bgSupport = true;
        #   #   start = ''
        #   #     ${pkgs.runtimeShell} ${pkgs.play-with-mpv} &
        #   #     waitPID=$!
        #   #   '';
        #   # }
        # ];
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
        ];
      };

      xrandrHeads = [
        {
          output = "HDMI-1";
          primary = true;
          monitorConfig = ''
            Option "PreferredMode" "2560x1440"
            Option "Position" "0 0"
          '';
        }
        {
          output = "eDP-1";
          monitorConfig = ''
            Option "PreferredMode" "2560x1600"
            Option "Position" "0 0"
          '';
        }
      ];
      resolutions = [
        {
          x = 2048;
          y = 1152;
        }
        {
          x = 1920;
          y = 1080;
        }
        {
          x = 2560;
          y = 1440;
        }
        {
          x = 3072;
          y = 1728;
        }
        {
          x = 3840;
          y = 2160;
        }
      ];
    };

    # syncthing = {
    #   enable = true;
    #   user = "morp";
    #   group = "syncthing";
    #   package = pkgs.syncthing;
    #   #use tailscale https://init8.lol/syncthing-anywhere-with-tailscale/
    #   relay.enable = false;
    #   systemService = true;
    # };
  };

  age.secrets.sync-xps17-nixos.file = ../../secrets/sync-xps17-nixos.age;

  services.syncthing = {
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
      "xps17-nixos" = {id = "$(cat ${config.age.secrets.sync-xps17-nixos.path})";};
      # "coredns-server" = {id = "REALLY-LONG-COREDNS-SERVER-SYNCTHING-KEY-HERE";};
    };

    folders = {
      "Dropbox" = {
        path = "/home/morp/Dropbox";
        devices = ["xps17-nixos"];
        versioning = {
          type = "staggered";
          params = {
            cleanInterval = "3600";
            maxAge = "15768000";
          };
        };
      };
      # "coredns-config" = {
      #   path = "/data/coredns-config";
      #   devices = ["coredns-server"];
      #   versioning = {
      #     type = "simple";
      #     params = {
      #       keep = "10";
      #     };
      #   };
      # };
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

  # tailscale
  services.tailscale.enable = true;

  age.identityPaths = [
    "/home/morp/.ssh/id_ed25519"
  ];
  age.secrets.ts-xps17-nixos.file = ../../secrets/ts-xps17-nixos.age;

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
      ${tailscale}/bin/tailscale up --authkey=$(cat ${config.age.secrets.ts-xps17-nixos.path})
    '';
  };

  # networking
  # networking.hostName = "xps17-nixos";
  # networking.wireless.enable = true;
  # networking.networkmanager.enable = true;
  networking = {
    hostName = "xps17-nixos";
    networkmanager.enable = true;
    firewall = {
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
    nameservers = ["100.100.100.100" "8.8.8.8" "1.1.1.1"];
    search = ["tailc585e.ts.net"];
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
      bluez
      rustup
      brightnessctl
      xdragon
      keyd
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
      gdb
      libinput-gestures
      wmctrl
      fwupd
      mysql80
      dbeaver
      dig
      psmisc
      discord
      mycli
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
      nixops
      os-prober
      kitty
      android-tools
      android-studio
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
      # openconnect_unstable
      networkmanager
      # networkmanager-vpnc
      # networkmanager_dmenu
      # networkmanager-openconnect
      networkmanagerapplet
      # networkmanager-fortisslvpn

      # gaming
      chiaki
      # avrlibc
      # conda
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
        ];
      })
    ];
  };
}
