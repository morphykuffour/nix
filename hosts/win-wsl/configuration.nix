{
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:
with lib; let
  nixos-wsl = import ./nixos-wsl;
in {
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    nixos-wsl.nixosModules.wsl
  ];

  system.stateVersion = "unstable";
  hardware.opengl.enable = true;
  nixpkgs.config.allowUnfree = true;
  networking = {
    hostName = "win-wsl";
  };

  users.users.morp = {
    isNormalUser = true;
    home = "/home/morp";
    shell = pkgs.zsh;
    extraGroups = ["wheel"];
  };

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "morp";
    startMenuLaunchers = true;

    # Enable integration with Docker Desktop
    docker.enable = true;

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
    emacs
    file
    exa
    bat
    rsync
    stow
    binutils
  ];
}
