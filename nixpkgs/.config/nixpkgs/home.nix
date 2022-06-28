{ config, pkgs, lib, ... }:

{
  imports =
    [
      #./xdg.nix # TODO fix environment issue
      ./tmux.nix
      ./neovim.nix
    ];
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
  ];
}

