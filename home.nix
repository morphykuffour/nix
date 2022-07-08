{ config, current, pkgs, lib, ... }:

# let
# userConfig = import ./user.nix { };
# gitConfig = import ./modules/git.nix {};
# in
# ${getEnv "HOME"}
# with ; {

{
  imports =
    [
      # ./modules/tmux/tmux.nix
      # ./modules/shell.nix
      ./modules/i3.nix
      ./modules/polybar
      ./modules/spotify.nix
      ./modules/redshift.nix
      ./modules/pass.nix
      ./modules/fonts.nix
      ./modules/sxhkd.nix # TODO move to i3.nix
      ./modules/nvim.nix
      ./modules/rofi.nix
      # ./modules/nur.nix
    ];

  nixpkgs.config.allowUnfree = true;
  home.username = "morp";
  home.homeDirectory = "/home/morp";
  home.stateVersion = "22.05";

  services.clipmenu.enable = true;
  programs = {
    home-manager = {
      enable = true;
    };
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
      ];
    };
  };
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
    gh # github cli
    clipmenu
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
    # python
    # python3Full
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
    spotifyd # spotify deamon
    neofetch
    zathura
    viu
    mpv
    feh
    sublime
    surfraw
    ffmpeg
    nix-index
    redshift
    discord
    termite
    (python39.withPackages (pp: with pp; [
      pynvim
      pandas
      requests
      pip
      ipython
    ]))
  ];
}

