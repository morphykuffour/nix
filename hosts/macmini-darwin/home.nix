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

    # Temporarily disabled to prevent source file symlink issues
    # morphEmacs = {
    #   enable = true;
    # };

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
