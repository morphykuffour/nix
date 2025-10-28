{pkgs, ...}: {
  imports = [
    ../../modules/lf
    ../../modules/zathura
  ];

  programs = {
    home-manager = {
      enable = true;
    };

    # lazygit = {
    #   enable = true;
    #   settings = {
    #     git = {
    #       paging = {
    #         colorArg = "always";
    #         pager = "delta --color-only --dark --paging=never";
    #         useConfig = false;
    #       };
    #     };
    #   };
    # };
  };

  # TODO remove homebrew packages
  home = {
    username = "morph";
    stateVersion = "22.05";
    
    # Shell aliases
    shellAliases = {
      zathura = "open -a Zathura";
    };
    
    packages = with pkgs; [
      p7zip
      # eva
      ripgrep
      autojump
      pandoc
      croc
      # mpv
      # tree-sitter-grammars.tree-sitter-markdown
      # nodePackages.typescript-language-server
      # nodePackages.bash-language-server
      # sumneko-lua-language-server
      # nodePackages.typescript
      # nodePackages.prettier
      # nodePackages.pyright
      # nodePackages.insect
      # rust-analyzer
      # rnix-lsp
      # ccls
      # black
      # gopls
      # ccls
      # newsboat
      # dev packages
      # # gcc_multi
      # # avrlibc
      # # python2
      starship
      tealdeer
      jupyter
      ranger
      stylua
      cscope
      delta
      # cargo
      # atuin
      tmux
      kitty
      ruby
      edir
      curl
      # sbcl
      # stow
      zsh
      # qmk
      # exa
      eza
      fzf
      bat
      fd
      gh
      jq
      rage
      # go
      # python3
      # opam
      # python packages
      # (python39.withPackages (pp:
      #   with pp; [
      #     mysql-connector
      #     pynvim
      #     pandas
      #     conda
      #     requests
      #     pip
      #     i3ipc
      #     ipython
      #     dbus-python
      #     html2text
      #     keymapviz
      #   ]))
    ];
  };
}
