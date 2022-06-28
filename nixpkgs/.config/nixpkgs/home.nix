{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./modules/tmux/tmux.nix
      ./modules/fonts.nix
      ./modules/shell.nix
      ./modules/i3.nix
      ./modules/nvim/nvim.nix
    ];
  nixpkgs.overlays = [ (import ./overlays/main.nix) ];
  nixpkgs.config.allowUnfree = true;

  home.username = "morp";
  home.homeDirectory = "/home/morp";
  home.stateVersion = "22.05";

  programs.home-manager.enable = true;
  home.packages = with pkgs;[
    tmux
    zsh
    atuin
    starship
    exa
    bat
    kitty
    autojump
    conda
    ruby
    nyxt
    emacs
    edir
    delta
    ranger
    tldr
    notepadqq
    eva
    stylua
    jq
    curl
    ripgrep
    fd
    fzf
    nodejs
    spotify-tui
    spotify
    jupyter
  ];
}

