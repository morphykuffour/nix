{
  config,
  lib,
  pkgs,
  ...
}: let
  # emacs-overlay = import <emacs-overlay> {};
  # emacsGit = ../../../emacs-overlay/result/bin/emacs;
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
    package = emacsGit;
    install = true;
  };

  # home.sessionVariables = rec {
  #   EDITOR = ''emacsclient -nw -a \"\"'';
  #   GIT_EDITOR = EDITOR;
  #   VISUAL = ''emacsclient -cna \"\"'';
  # };

  # programs.emacs = {
  #   enable = true;
  #   package = emacs-overlay.emacsWithPackagesFromUsePackage {
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

  # services.emacs.enable = ! pkgs.stdenv.isDarwin;
}
