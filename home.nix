{
  config,
  current,
  pkgs,
  lib,
  plover,
  ...
}: {
  imports = [
    ./modules/i3.nix
    ./modules/spotify.nix
    ./modules/redshift.nix
    ./modules/pass.nix
    ./modules/fonts.nix
    ./modules/sxhkd.nix
    # TODO make tailscale work
    # ./modules/tailscale.nix
    # ./modules/nvim.nix
    ./modules/rofi.nix
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
        obs-gstreamer
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  home = {
    username = "morp";
    homeDirectory = "/home/morp";
    stateVersion = "22.05";

    packages = with pkgs; [
      kitty
      tmux
      zsh
      atuin
      starship
      exa
      bat
      tealdeer
      fd
      gh
      clipmenu
      delta
      cscope
      pastel
      conda
      jupyter
      ruby
      edir
      ranger
      stylua
      cargo
      jq
      curl
      fzf
      # nodejs
      sbcl
      neomutt
      mu
      isync
      msmtp
      pass
      himalaya
      calibre
      emacs
      slides
      sxhkd
      inkscape
      gimp
      blender
      # kicad
      # ffmpeg
      eva
      aria2
      hyperfine
      hexyl
      ripgrep
      autojump
      pandoc
      croc
      spotify
      neofetch
      zathura
      go
      viu
      mpv
      feh
      sublime
      surfraw
      nix-index
      redshift
      termite
      plover
      tree-sitter
      rnix-lsp
      gopls
      ccls
      fpp
      tree-sitter-grammars.tree-sitter-markdown
      sumneko-lua-language-server
      nodePackages.typescript-language-server
      nodePackages.insect
      nodePackages.mermaid-cli
      nodePackages.bash-language-server
      nodePackages.pyright
      nodePackages.typescript
      nodePackages.prettier
      mathpix-snipping-tool
      black
      rust-analyzer
      postman
      openssl
      protonvpn-gui
      protonmail-bridge
      play-with-mpv
      rustdesk
      # python2
      (python39.withPackages (pp:
        with pp; [
          pynvim
          pandas
          requests
          pip
          i3ipc
          ipython
          dbus-python
          html2text
          keymapviz
        ]))
    ];
  };
}
