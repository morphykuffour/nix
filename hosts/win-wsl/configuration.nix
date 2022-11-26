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
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

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

  environment.systemPackages = with pkgs; [
    git
    wget
    vim
    zsh
    neovim
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
