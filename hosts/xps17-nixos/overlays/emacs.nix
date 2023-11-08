with rec {
  emacs-overlay = import (builtings.fetchTarball {url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;});
  pkgs = import <nixpkgs> {overlays = [emacs-overlay];};
};
  pkgs.emacsGcc
