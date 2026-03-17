{pkgs, ...}: {
  imports = [
    ../../modules/lf
    ../../modules/zathura
    ../../modules/hammerspoon.nix
  ];

  programs = {
    home-manager = {
      enable = true;
    };

    # Emacs with packages - config is stowed from ~/dots/emacs
    emacs = {
      enable = true;
      package = pkgs.emacs30.override {
        withNativeCompilation = true;
      };
      extraPackages = epkgs:
        with epkgs; [
          # Core
          use-package
          gcmh

          # Evil ecosystem
          evil
          evil-collection
          evil-org
          evil-commentary
          undo-tree

          # Completion
          counsel
          counsel-tramp
          ivy
          swiper
          flx

          # Git
          magit
          magit-delta
          git-commit
          magit-section
          with-editor

          # Org ecosystem
          org-roam
          org-roam-ui
          org-msg

          # Terminal
          vterm
          multi-vterm
          eat

          # UI/UX
          which-key
          rainbow-delimiters
          olivetti
          deadgrep
          circadian
          autothemer
          gruvbox-theme
          modus-themes

          # Dired
          dired-hide-dotfiles
          nerd-icons-dired
          nerd-icons
          async

          # Editing
          yasnippet
          markdown-mode
          nix-mode
          slime
          pdf-tools

          # Utilities
          exec-path-from-shell
          atomic-chrome
        ];
    };
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
      # Archive/compression
      p7zip
      unar
      xz
      zstd

      # Shell & navigation
      autojump
      starship
      zsh
      atuin
      mcfly

      # File tools
      ripgrep
      fd
      fzf
      eza
      bat
      tree
      edir
      rename
      fswatch
      watchexec

      # Git & version control
      gh
      delta

      # Text/document processing
      pandoc
      jq
      glow
      gum

      # Development tools
      neovim
      tmux
      kitty
      entr
      cmake
      meson
      ninja
      gnused
      moreutils

      # Languages & runtimes
      go
      lua
      luarocks
      nodejs
      ruby

      # Python tools
      pipx
      poetry
      uv
      jupyter

      # System monitoring
      btop
      htop
      dog
      duf
      dust
      tokei

      # Media & documents
      ffmpeg
      imagemagick
      exiftool
      tesseract
      mupdf

      # Network & communication
      curl
      wget
      aria2
      socat
      croc
      qrcp

      # Email tools
      neomutt
      isync
      notmuch
      msmtp

      # Security & encryption
      age
      rage

      # Nix tools
      deadnix

      # Other utilities
      stow
      tealdeer
      todoist
      ranger
      stylua
      cscope
      minicom
    ];
  };
}
