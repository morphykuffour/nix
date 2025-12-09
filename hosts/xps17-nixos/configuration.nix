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
    ./rustdesk-client.nix
    # ../../modules/mullvad
    ../../modules/kanata
    # ./fakwin.nix
    # ./restic.nix
    # ./dslr.nix
  ];

  # Bootloader.

  # zfs specific
  boot.supportedFilesystems = ["zfs"];
  networking.hostId = "cc5926fa";

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.enableCryptodisk = true;

  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/f134f473-95f4-4037-a167-600084b82a7e"; ## Use blkid to find this UUID
      # Required even if we're not using LVM
      preLVM = true;
    };
  };

  # Enable networking
  networking = {
    hostName = "xps17-nixos";
    networkmanager.enable = true;
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    firewall = {
      enable = true;

      # always allow traffic from tailscale network
      trustedInterfaces = ["tailscale0"];

      # allow the Tailscale UDP port through the firewall
      allowedUDPPorts = [config.services.tailscale.port];

      # let you SSH in over the public internet
      allowedTCPPorts = [22 24800]; # 24800 = Deskflow/Synergy/Barrier/InputLeap

      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
    };
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
  };

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
  # allow swaylock to authenticate
  security.pam.services.swaylock = {};
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  # bluetooth
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  services = {
    emacs = {
      # package = pkgs.emacs-unstable;
      # package = pkgs.emacs-git;
      package = pkgs.emacs;
      enable = true;
      install = true;
    };

    pulseaudio.enable = false;
    blueman.enable = true;

    # printing.enable = true;

    # avahi = {
    #   nssmdns4 = true;
    #   enable = true;
    #   openFirewall = true;
    #   publish = {
    #     enable = true;
    #     userServices = true;
    #     domain = true;
    #   };
    #   allowInterfaces = ["wlp0s20f3" "tailscale0"];
    # };

    # libinput moved out of xserver
    libinput = {
      enable = true;
      # touchpad.disableWhileTyping = true;
    };

    # Desktop manager moved out of xserver
    desktopManager.plasma6.enable = true;

    # Minimal TUI greeter: launch sway by default (force Intel iGPU for wlroots)
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember-session --debug /var/log/tuigreet.log --xsessions /run/current-system/sw/share/xsessions --sessions /run/current-system/sw/share/wayland-sessions --cmd '${pkgs.dbus}/bin/dbus-run-session env WLR_DRM_DEVICES=/dev/dri/by-path/pci-0000:00:02.0-card ${pkgs.sway}/bin/sway --unsupported-gpu'";
          user = "greeter";
        };
      };
    };

    xserver = {
      enable = true;

      xkb = {
        layout = "us";
        variant = "";
      };

      displayManager.startx.enable = false;

      # Use proprietary NVIDIA driver instead of nouveau
      videoDrivers = ["nvidia"];

      windowManager = {
        i3 = {
          enable = true;
          package = pkgs.i3;
        };
      };
    };
  };

  # Enable graphics stack (GL/Vulkan, etc.)
  hardware.graphics.enable = true;

  # NVIDIA PRIME offloading (Intel iGPU + NVIDIA dGPU)
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.production;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Ensure nouveau is not used to prevent conflicts with the NVIDIA driver
  boot.blacklistedKernelModules = ["nouveau"];
  # Double-blacklist nouveau at kernel cmdline to avoid early load
  boot.kernelParams = [ "modprobe.blacklist=nouveau" ];

  # For PRIME offload: Configure X to only use Intel GPU, NVIDIA used on-demand
  # This prevents the "Failed to create pixmap" error on the NVIDIA GPU
  services.xserver.config = ''
    Section "ServerLayout"
      Identifier "layout"
      Screen 0 "Screen-intel"
    EndSection

    Section "Device"
      Identifier "Device-intel"
      Driver "modesetting"
      BusID "PCI:0:2:0"
      Option "DRI" "3"
    EndSection

    Section "Screen"
      Identifier "Screen-intel"
      Device "Device-intel"
    EndSection
  '';

  # On suspend, terminate the user session so wake shows greetd; on resume, switch to greetd TTY
  powerManagement.enable = true;

  # Replace deprecated suspendCommands/resumeCommands with systemd services
  systemd.services.terminate-user-on-suspend = {
    description = "Terminate user session on suspend";
    wantedBy = ["sleep.target"];
    before = ["sleep.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/loginctl terminate-user morph || true";
    };
  };

  systemd.services.switch-to-greetd-on-resume = {
    description = "Switch to greetd TTY on resume";
    after = ["suspend.target"];
    wantedBy = ["suspend.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kbd}/bin/chvt 1 || true";
    };
  };

  # Remove Plasma+i3 user-service integration when using Sway
  systemd.user.services.plasma-i3wm = lib.mkForce { wantedBy = []; serviceConfig = {}; };
  systemd.user.services.plasma-workspace-x11.after = lib.mkForce [];
  systemd.user.services.plasma-kwin_x11.enable = lib.mkForce false;

  users.users.morph = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "Morphy Kuffour";
    extraGroups = ["networkmanager" "wheel" "libvirtd" "docker"];
    packages = with pkgs; [];
  };

  programs = {
    sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraPackages = with pkgs; [
        swaylock
        swayidle
        wl-clipboard
        wtype
        rofi
        wofi
        grim
        slurp
        swaybg
        sway-contrib.grimshot
      ];
    };
    # Steam
    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };
    # obs-studio = {
    #   enable = true;
    #   plugins = with pkgs; [ obs-studio-plugins.wlrobs ];
    # };
    kdeconnect.enable = true;

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

  # vms
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };
  # Graphical management for libvirt/KVM VMs
  programs.virt-manager.enable = true;
  # Optional but useful for USB passthrough in VMs
  virtualisation.spiceUSBRedirection.enable = true;
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system = {
    # stateVersion = config.system.nixos.release;
    stateVersion = "23.05"; # Did you read the comment?
    autoUpgrade = {
      enable = false;
      allowReboot = false;
    };
  };

  # sudoless
  # security.sudo.wheelNeedsPassword = false;

  environment.interactiveShellInit = ''
    alias c99='gcc'
  '';

  # Allow running non-NixOS, dynamically linked binaries (like the patched QEMU from Docker)
  # by providing the needed shared libraries via nix-ld.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      libjpeg_turbo
      libslirp
      pixman
      dtc              # provides libfdt.so
      systemd          # provides libudev
      libusb1
      glib             # provides libgio, libgobject, libglib, libgmodule
      zstd
      liburing
      libgcrypt
      libaio
      bzip2
    ];
  };

  # Wayland-friendly environment
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    XDG_SESSION_TYPE = "wayland";
    WLR_NO_HARDWARE_CURSORS = "1"; # helps on Nvidia if cursor glitches
    # Force wlroots to pick the Intel iGPU DRM device (PCI:0:2:0) to avoid NVIDIA
    WLR_DRM_DEVICES = "/dev/dri/by-path/pci-0000:00:02.0-card";
  };

  # Create xinitrc.d script to initialize systemd user session variables for X11 when needed
  environment.etc."X11/xinit/xinitrc.d/50-systemd-user.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      # Import environment variables into systemd user session
      systemctl --user import-environment PATH DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_CLASS XDG_SESSION_DESKTOP
      # Update dbus activation environment
      dbus-update-activation-environment --systemd --all
      # Start graphical session target for user services (fakwin, deskflow, etc.)
      systemctl --user start graphical-session.target
    '';
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
    gnumake
    xorg.xbacklight
    xorg.xinit
    xorg.xauth
    sway
    swaybg
    swaylock
    swayidle
    wl-clipboard
    wtype
    rofi
    wofi
    grim
    slurp
    sway-contrib.grimshot
    alsa-utils
    autorandr
    xdotool
    xdg-user-dirs
    pciutils
    usbutils
    # ventoy-bin
    rustup
    rustc
    brightnessctl
    # xdragon
    keyd
    dconf-editor
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
    # Virtualisation tooling for Windows/libvirt workflow
    swtpm
    vagrant
    # vagrant-libvirt  # Not available as standalone package; use vagrant plugin if needed
    gdb
    libinput-gestures
    wmctrl
    fwupd
    # mysql80
    dbeaver-bin
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
    age
    rage
    uxplay
    arandr
    libclang
    # libstdcxx5
    ctags
    zsh-completions
    networkmanager
    networkmanagerapplet
    dmenu
    rofi
    # avahi
    eza
    discord
    # gimp
    # mullvad
    kitty
    mpv
    code-cursor
    anki
    rustdesk
    claude-code
    deskflow
    tigervnc
    python313Packages.i3ipc
    filezilla
    notepad-next
    ntfs3g
    ntfsprogs

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
