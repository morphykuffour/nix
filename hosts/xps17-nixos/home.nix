{
  config,
  current,
  pkgs,
  lib,
  plover,
  ...
}: {
  imports = [
    ../../modules/i3.nix
    ../../modules/redshift.nix
    ../../modules/pass.nix
    ../../modules/fonts.nix
    ../../modules/zathura
    # ../../modules/hyprland
    # ./modules/nvim.nix
    ../../modules/picom.nix
  ];

  services.clipmenu.enable = true;
  programs = {
    home-manager = {
      enable = true;
    };
    # obs-studio = {
    #   enable = true;
    #   plugins = with pkgs.obs-studio-plugins; [
    #     wlrobs
    #     obs-gstreamer
    #   ];
    # };
    lazygit = {
      enable = true;
      settings = {
        git = {
          paging = {
            colorArg = "always";
            pager = "delta --color-only --dark --paging=never";
            useConfig = false;
          };
        };
      };
    };
    vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions; [
        dracula-theme.theme-dracula
        vscodevim.vim
        yzhang.markdown-all-in-one
        ms-toolsai.jupyter
      ];
    };
  };

  nixpkgs = {
    config.allowUnfree = true;
  };

  home = {
    username = "morp";
    homeDirectory = "/home/morp";
    stateVersion = "22.05";
    packages = with pkgs; [
      tmux
      zsh
      # atuin
      starship
      exa
      bat
      tealdeer
      fd
      gh
      clipmenu
      delta
      # cscope
      # pastel
      jupyter
      ruby
      edir
      ranger
      stylua
      cargo
      jq
      curl
      fzf
      sbcl
      neomutt
      mu
      isync
      msmtp
      pass
      # calibre
      # slides
      # sxhkd
      # inkscape
      # gimp
      # blender
      # kicad
      # ffmpeg
      eva
      mcfly
      # aria2
      # hyperfine
      hexyl
      ripgrep
      autojump
      pandoc
      croc
      spotify
      # neofetch
      zathura
      go
      # viu
      # mpv
      feh
      sublime
      surfraw
      nix-index
      redshift
      # termite
      # plover
      tree-sitter
      rnix-lsp
      gopls
      ccls
      fpp
      # tree-sitter-grammars.tree-sitter-markdown
      # sumneko-lua-language-server
      # nodePackages.typescript-language-server
      nodePackages.insect
      # nodePackages.mermaid-cli
      # nodePackages.bash-language-server
      # nodePackages.pyright
      # nodePackages.typescript
      nodePackages.prettier
      # ccls
      # mathpix-snipping-tool
      black
      # rust-analyzer
      postman
      openssl
      protonvpn-gui
      # protonmail-bridge
      # play-with-mpv
      # rustdesk
      file
      newsboat
      # neovim
      # fasd
      texlive.combined.scheme-full
      # python2

      # keeb packages
      # via
      qmk
      qmk-udev-rules
      # gcc_multi
      # avrlibc

      # documents packages
      p7zip
      ruby
      emacs

      # csv
      xsv

      # finance
      ledger

      # python packages
      (python39.withPackages (pp:
        with pp; [
          pynvim
          pandas
          # reticulate needs conda
          conda
          requests
          pip
          i3ipc
          ipython
          dbus-python
          html2text
          keymapviz
          mysql-connector
          pipx
          pyqt5
          ueberzug
        ]))
    ];
  };
}
