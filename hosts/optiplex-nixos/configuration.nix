# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # ./zfs.nix
  ];

  nixpkgs.config.allowUnfree = true;

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  boot.extraModulePackages = [
    config.boot.kernelPackages.rtl8814au
  ];

  networking.hostName = "optiplex-nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  services = {
    emacs = {
      # package = pkgs.emacs-unstable;
      # package = pkgs.emacs-git;
      package = pkgs.emacs;
      enable = true;
      install = true;
    };

    xserver = {
      desktopManager = {
        gnome = {
          enable = true;
        };

        # plasma5 = {
        #   enable = true;
        # };

        # mate = {
        #   enable = true;
        # };
      };
      enable = true;
      displayManager.gdm.enable = true;
      # displayManager = {
      #   startx.enable = true;
      #   defaultSession = "plasma";
      #   autoLogin = {
      #     enable = true;
      #     user = "morph";
      #   };
      #   sddm.enable = true;
      # };

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
    # vscode-server.enable = true;
    # And then enable them for the relevant users:
    # systemctl --user enable auto-fix-vscode-server.service

    syncthing = {
      enable = true;
      dataDir = "/home/morph";
      openDefaultPorts = true;
      configDir = "/home/morph/.config/syncthing";
      user = "morph";
      group = "users";
      guiAddress = "127.0.0.1:8384";
      overrideDevices = true;
      overrideFolders = true;
      settings.devices = {
        "xps17-nixos" = {id = "MX3EJ5F-VQWN4O5-7DB2MZG-BQPUKVT-W6KJJJM-4GBZ7RA-ZRVXERL-GU5ZMQS";};
        "macmini-darwin" = {id = "OK4365M-ZZC4CDT-A6W2YF2-MPIX3GR-FYZIWWJ-5QS6RYM-5KYU35K-SLYBHQO";};
      };

      settings.folders = {
        # "Org" = {
        #   path = "/home/morph/Org/";
        #   id = "Org";
        #   devices = ["xps17-nixos" "macmini-darwin"];
        #   versioning = {
        #     type = "staggered";
        #     params = {
        #       cleanInterval = "3600";
        #       maxAge = "15768000";
        #     };
        #   };
        # };

        "iCloud" = {
          path = "/home/morph/iCloud/";
          id = "iCloud";
          devices = ["xps17-nixos" "macmini-darwin"];
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

  # Configure keymap in X11
  #   "eurosign:e";
  #   "caps:escape" # map caps to escape.
  # };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
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

  # Enable touchpad support (enabled default in most desktopManager).

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;
    users.morph = {
      isNormalUser = true;
      extraGroups = ["networkmanager" "wheel"]; # Enable ‘sudo’ for the user.
      shell = pkgs.zsh;
      # packages = with pkgs; [ thunderbird ];
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  programs.zsh.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # age.identityPaths = [
  #   "/home/morph/.ssh/id_ed25519"
  # ];
  # age.secrets.ts-optiplex-nixos.file = ../../secrets/ts-optiplex-nixos.age;

  # tailscale
  # services.tailscale.enable = true;
  # # create a oneshot job to authenticate to Tailscale
  # systemd.services.tailscale-autoconnect = {
  #   description = "Automatic connection to Tailscale";

  #   # make sure tailscale is running before trying to connect to tailscale
  #   after = ["network-pre.target" "tailscale.service"];
  #   wants = ["network-pre.target" "tailscale.service"];
  #   wantedBy = ["multi-user.target"];

  #   # set this service as a oneshot job
  #   serviceConfig.Type = "oneshot";

  #   # have the job run this shell script
  #   script = with pkgs; ''
  #     # wait for tailscaled to settle
  #     sleep 2

  #     # check if we are already authenticated to tailscale
  #     status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
  #     if [ $status = "Running" ]; then # if so, then do nothing
  #       exit 0
  #     fi

  #     # otherwise authenticate with tailscale
  #     ${tailscale}/bin/tailscale up --authkey=$(cat ${config.age.secrets.ts-optiplex-nixos.path})
  #   '';
  # };

  # networking.firewall = {
  #   # warning: Strict reverse path filtering breaks Tailscale
  #   # exit node use and some subnet routing setups.
  #   checkReversePath = "loose";
  #   # enable the firewall
  #   enable = true;

  #   # always allow traffic from your Tailscale network
  #   trustedInterfaces = ["tailscale0"];

  #   # allow the Tailscale UDP port through the firewall
  #   allowedUDPPorts = [config.services.tailscale.port];

  #   # allow you to SSH in over the public internet
  #   allowedTCPPorts = [22];
  # };

  environment.systemPackages = with pkgs; [
    vim
    wget
    discord
    tealdeer
    xclip
    git
    stow
    zsh
    tmux
    starship
    # atuin
    kitty
    ranger
    eza
    autojump
    bat
    which
    gnumake
    tailscale
    vscode
    rustup
    cargo
    rage
    brave
    firefox
    mcfly
    neovim
    flashrom
  ];
}
