{
  lib,
  pkgs,
  config,
  nixos-wsl,
  modulesPath,
  ...
}: {
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    nixos-wsl.nixosModules.wsl
  ];

  # Set your time zone.
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "unstable";
  hardware.opengl.enable = true;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;
  networking = {
    hostName = "win-wsl";
    dhcpcd.enable = false;
  };

  users = {
    defaultUserShell = pkgs.zsh;
    users.morp = {
      isNormalUser = true;
      home = "/home/morp";
      shell = pkgs.zsh;
      extraGroups = ["wheel"];
    };

    users.root = {
      # Otherwise WSL fails to login as root with "initgroups failed 5"
      extraGroups = ["root"];
    };
  };

  services = {
    openssh.enable = true;
    # And then enable them for the relevant users:
    # systemctl --user enable auto-fix-vscode-server.service
    vscode-server.enable = true;
  };

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    defaultUser = "morp";
    startMenuLaunchers = true;

    # Enable integration with Docker Desktop
    # docker-desktop.enable = true;

    # tailscale.enable = true;
  };

  # Enable nix flakes
  nix = {
    package = pkgs.nixFlakes;
    autoOptimiseStore = true;
    useSandbox = true;
    settings.trusted-users = ["root" "morp" "@wheel"];

    binaryCaches = [
      "https://nix-community.cachix.org"
    ];
    binaryCachePublicKeys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  security.sudo.wheelNeedsPassword = false;

  # Disable systemd units that don't make sense on WSL
  systemd.services."serial-getty@ttyS0".enable = false;
  systemd.services."serial-getty@hvc0".enable = false;
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@".enable = false;

  systemd.services.firewall.enable = false;
  systemd.services.systemd-resolved.enable = false;
  systemd.services.systemd-udevd.enable = false;

  # Don't allow emergency mode, because we don't have a console.
  systemd.enableEmergencyMode = false;

  systemd.services.nixs-wsl-systemd-fix = {
    description = "Fix the /dev/shm symlink to be a mount";
    unitConfig = {
      DefaultDependencies = "no";
      # Before = "sysinit.target";
      Before = ["sysinit.target" "systemd-tmpfiles-setup-dev.service" "systemd-tmpfiles-setup.service" "systemd-sysctl.service"];
      ConditionPathExists = "/dev/shm";
      ConditionPathIsSymbolicLink = "/dev/shm";
      ConditionPathIsMountPoint = "/run/shm";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${pkgs.coreutils-full}/bin/rm /dev/shm"
        "/run/wrappers/bin/mount --bind -o X-mount.mkdir /run/shm /dev/shm"
      ];
    };
    wantedBy = ["sysinit.target"];
  };

  # emacs package
  services.emacs = {
    enable = true;
    package = pkgs.emacsGit;
    install = true;
  };

  # import emacs config as a submodule
  nixpkgs.overlays = [
    (import ../../third_party/emacs-overlay)
    # (import (builtins.fetchTarball {
    #   url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
    # }))
  ];

  environment.systemPackages = with pkgs; [
    git
    wget
    vim
    zsh
    delta
    home-manager
    curl
    jq
    # emacs
    file
    exa
    bat
    rsync
    stow
    binutils
    exa
    autojump
    atuin
    starship
    tmux
    tealdeer
    xclip
    nodejs
    ranger
    gnumake
    ripgrep
    fzf
  ];
}
