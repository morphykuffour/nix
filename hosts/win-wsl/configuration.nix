{
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:
with lib; let
  nixos-wsl = import ./NixOS-WSL;
in {
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
  };

  users = {
      defaultUserShell = pkgs.zsh;
      users.morp = {
      isNormalUser = true;
      home = "/home/morp";
      shell = pkgs.zsh;
      extraGroups = ["wheel"];
    };
  };

  services.openssh.enable = true;
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
  ];

}
