{
  config,
  lib,
  pkgs,
  ...
}: let
  emacs-overlay = import <emacs-overlay> {};
in {
  # home.file.".emacs.d/init.el".source = ./init.el;

  # home.packages = with pkgs; [
  #   graphviz
  #   noweb
  #   sqlite
  # ];

  # TODO: eventually move to emacsGit using overlay and flake input
  # https://github.com/nix-community/emacs-overlay
  services.emacs = {
    enable = true;
    # package = pkgs.emacsUnstable;
    package = pkgs.emacs-overlay.emacsGit;
    install = true;
  };

  # nixpkgs.overlays = [
  #   (import (builtins.fetchTarball {
  #     url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
  #   }))
  # ];
  # home.sessionVariables = rec {
  #   EDITOR = ''emacsclient -nw -a \"\"'';
  #   GIT_EDITOR = EDITOR;
  #   VISUAL = ''emacsclient -cna \"\"'';
  # };

  # programs.emacs = {
  #   enable = true;
  #   package = pkgs.emacsWithPackagesFromUsePackage {
  #     alwaysEnsure = true;
  #     config = ./init.el;
  #     # override = epkgs: epkgs // {
  #     #   noweb-mode = pkgs.noweb;
  #     # };
  #   };
  # };

  # programs.fish.shellAliases = lib.mkIf (config.programs.fish.enable) rec {
  #   e = "emacsclient -na \"\"";
  #   ec = e + " -c";
  #   et = "emacsclient -nw -a \"\"";
  # };

  services.emacs.enable = ! pkgs.stdenv.isDarwin;
}
