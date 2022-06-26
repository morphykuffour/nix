{ config, pkgs, lib, vimUtils, ... }:

let
  # installs a vim plugin from git with a given tag / branch
  pluginGit = ref: repo: vimUtils.buildVimPluginFrom2Nix {
    pname = "${lib.strings.sanitizeDerivationName repo}";
    version = ref;
    src = builtins.fetchGit {
      url = "https://github.com/${repo}.git";
      ref = ref;
    };
  };

  # always installs latest version
  plugin = pluginGit "HEAD";
in
{
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
  ];

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  programs.neovim = {
    enable = true;
    package = pkgs.neovim-nightly;
  };

}
