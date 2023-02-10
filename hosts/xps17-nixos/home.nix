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
  };

  nixpkgs = {
    config.allowUnfree = true;
    # overlays = [ (import emacs-overlay) ];
  };

  home = {
    username = "morp";
    homeDirectory = "/home/morp";
    stateVersion = "22.05";
    packages = with pkgs; [
      # emacs packages
      # emacs-all-the-icons-fonts

      # (pkgs.emacsWithPackagesFromUsePackage {
      #   config = ./dot/emacs.el;
      #   defaultInitFile = true;
      #   alwaysEnsure = true;
      #   package = pkgs.emacsPgtk;

      #   override = epkgs:
      #     epkgs
      #     // {
      #       tree-sitter-langs = epkgs.tree-sitter-langs.withPlugins (
      #         # Install all tree sitter grammars available from nixpkgs
      #         grammars: builtins.filter lib.isDerivation (lib.attrValues grammars)
      #       );
      #     };
      # })

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
      # protonvpn-gui
      # protonmail-bridge
      # play-with-mpv
      # rustdesk
      file
      newsboat
      neovim
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
      # emacs

      # csv
      xsv

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
