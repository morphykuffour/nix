{
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}: {
  imports = ["${modulesPath}/profiles/minimal.nix"];

  hardware.opengl.enable = true;

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

  users.users.morp = {
    isNormalUser = true;
    home = "/home/morp";
    shell = pkgs.zsh;
    extraGroups = ["wheel"];
  };

  # Enable nix flakes
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
