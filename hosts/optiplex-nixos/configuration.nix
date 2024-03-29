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
    ./zfs.nix
  ];
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "optiplex-nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  # Enable the X11 windowing system.
  services = {
    xserver = {
      desktopManager = {
        plasma5 = {
          enable = true;
        };

        # mate = {
        #   enable = true;
        # };
      };

      enable = true;
      displayManager = {
        startx.enable = true;
        defaultSession = "plasma";
        autoLogin = {
          enable = true;
          user = "${user}";
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
    # vscode-server.enable = true;
    # And then enable them for the relevant users:
    # systemctl --user enable auto-fix-vscode-server.service

    # syncthing = {
    #   enable = true;
    #   dataDir = "/home/${user}";
    #   openDefaultPorts = true;
    #   configDir = "/home/${user}/.config/syncthing";
    #   user = "${user}";
    #   group = "users";
    #   guiAddress = "127.0.0.1:8384";
    #   overrideDevices = true;
    #   overrideFolders = true;
    #   devices = {
    #     "xps17-nixos" = {id = "44LYB6O-ELZWVNP-5R576R3-MRD3MM2-FXORGWG-WRC26ZQ-JAMWKRS-5SCNUAY";};
    #     "rpi3b-ubuntu" = {id = "TTEQED5-YB5HDQQ-4OYRRUE-PQMO7XF-TWCNSQ7-4SFRM5X-N6C3IBY-ELN2XQV";};
    #     "macmini-darwin" = {id = "OK4365M-ZZC4CDT-A6W2YF2-MPIX3GR-FYZIWWJ-5QS6RYM-5KYU35K-SLYBHQO";};
    #   };

    #   folders = {
    #     "Org" = {
    #       path = "/home/${user}/Org/";
    #       id = "prsu2-hrpwq";
    #       devices = ["xps17-nixos" "rpi3b-ubuntu" "macmini-darwin"];
    #       versioning = {
    #         type = "staggered";
    #         params = {
    #           cleanInterval = "3600";
    #           maxAge = "15768000";
    #         };
    #       };
    #     };

    #     "iCloud" = {
    #       path = "/home/${user}/iCloud/";
    #       id = "iCloud";
    #       devices = ["xps17-nixos" "rpi3b-ubuntu" "macmini-darwin"];
    #       versioning = {
    #         type = "staggered";
    #         params = {
    #           cleanInterval = "3600";
    #           maxAge = "15768000";
    #         };
    #       };
    #     };
    #   };
    # };
  };

  # Configure keymap in X11
  #   "eurosign:e";
  #   "caps:escape" # map caps to escape.
  # };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;
    users.${user} = {
      isNormalUser = true;
      extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
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

  # List services that you want to enable:

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
  system.stateVersion = "22.05"; # Did you read the comment?

  # List packages installed in system profile. To search, run:
  # $ nix search wget
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
    brave
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
  ];
  nix.settings.experimental-features = ["nix-command" "flakes"];

  age.identityPaths = [
    "/home/${user}/.ssh/id_ed25519"
  ];
  age.secrets.ts-optiplex-nixos.file = ../../secrets/ts-optiplex-nixos.age;

  # tailscale
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
      ${tailscale}/bin/tailscale up --authkey=$(cat ${config.age.secrets.ts-optiplex-nixos.path})
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
}
