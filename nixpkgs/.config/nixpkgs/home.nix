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
      # ./modules/email
      ./modules/spotify.nix
      ./modules/redshift.nix
      ./modules/pass.nix
      ./modules/fonts.nix
      ./modules/sxhkd.nix
      ./modules/nvim.nix
      ./modules/rofi.nix
      # ./modules/nur.nix
    ];


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
  nixpkgs.config.allowUnfree = true;
  home = {
    username = "morp";
    homeDirectory = "/home/morp";
    stateVersion = "22.05";

    packages = with pkgs;[
      # terminal devtools
      kitty # terminal 
      tmux # terminal multiplexor
      zsh # shell
      atuin # history management
      starship # shell prompt
      calibre
      exa # shell ls
      bat # shell bat
      tealdeer # faster tldr
      fd # faster find
      gh # github cli
      clipmenu
      delta # better git pager
      cscope
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
      cargo
      jq # parse json streams
      curl # work with urls
      fzf # fuzzy finder
      nodejs # js compiler
      croc
      blender
      kicad
      spotify-tui # spotify in terminal
      spotify # spotify gui
      spotifyd # spotify deamon
      neofetch
      zathura
      go
      viu
      inkscape
      gimp
      blender
      mpv
      feh
      sublime
      surfraw
      ffmpeg
      nix-index
      vial
      redshift
      discord
      termite
      # qmk
      sbcl
      (python39.withPackages (pp: with pp; [
        pynvim
        pandas
        requests
        pip
        ipython
        dbus-python
        html2text
        icalendar
        keymapviz
        virtualenv

      ]))
    ];
  };
}

