{ config, current, pkgs, lib, ... }:

# let
# userConfig = import ./user.nix { };
# gitConfig = import ./modules/git.nix {};
# in
# with ; {

{
  imports =
    [
      # ./modules/tmux/tmux.nix
      # ./modules/shell.nix
      # ./modules/polybar.nix
      ./modules/fonts.nix
      ./modules/sxhkd.nix
      ./modules/nvim/nvim-hm.nix
      ./modules/rofi.nix
      # ./modules/nvim.nix
    ];
  nixpkgs.overlays = [ (import ./overlays/main.nix) ];
  nixpkgs.config.allowUnfree = true;

  home.username = "morp";
  home.homeDirectory = "/home/morp";
  home.stateVersion = "22.05";

  xsession.windowManager.i3 = import ./modules/i3.nix {
    inherit current lib pkgs;
  };


  programs.home-manager.enable = true;
  home.packages = with pkgs;[

    # terminal devtools
    kitty # terminal 
    tmux # terminal multiplexor
    zsh # shell
    atuin # history management
    starship # shell prompt
    exa # shell ls
    bat # shell bat
    tealdeer # faster tldr
    fd # faster find
    delta # better git pager
    pastel # view rgb codes
    neomutt # email client
    isync # sync mail locally
    msmtp # send mail
    pass # encrypt passwords
    # neovim#-nightly # ppde
    # tldr
    eva # better bc (calculator)
    aria2 # faster downloads
    hyperfine # benchmarking tool
    hexyl # hex viewer
    ripgrep # faster grep
    autojump # jump to directories
    conda # python env management
    jupyter # notebooks for prototyping
    ruby # ruby interpreter
    nyxt # script websites with sliime and emacs (browser)
    slides # terminal presentations
    emacs # operating system
    edir # feature rich vidir
    ranger # slower lf
    stylua # lua formatter
    jq # parse json streams
    curl # work with urls
    fzf # fuzzy finder
    nodejs # js compiler
    spotify-tui # spotify in terminal
    spotify # spotify gui
    mpv
    feh
    sublime
    surfraw
    (python39.withPackages (pp: with pp; [
      pynvim
    ]))
  ];
}

