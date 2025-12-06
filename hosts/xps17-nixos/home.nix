{
  inputs,
  config,
  current,
  pkgs,
  lib,
  plover,
  user,
  agenix,
  ...
}: {
  imports = [
    ../../modules/i3.nix
    ../../modules/pass.nix
    ../../modules/fonts.nix
    ../../modules/zathura
    ../../modules/lf
    # ../../modules/nvim.nix
    # ../../modules/redshift.nix
    ./fakwin.nix
    ../../modules/picom.nix
    ../../modules/grobi
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
    vscode = {
      enable = true;
      profiles.default.extensions = with pkgs.vscode-extensions; [
        dracula-theme.theme-dracula
        vscodevim.vim
        yzhang.markdown-all-in-one
        ms-toolsai.jupyter
      ];
    };
  };

  # Launch Deskflow (Barrier successor) GUI on login; configure server via its UI
  systemd.user.services.deskflow = {
    Unit = {
      Description = "Deskflow keyboard/mouse sharing";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session-pre.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.deskflow}/bin/deskflow";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  # Note: nixpkgs.config is set at system level in configuration.nix
  # Removed nixpkgs block as it conflicts with home-manager.useGlobalPkgs = true

  home = {
    username = "morph";
    homeDirectory = "/home/morph";
    stateVersion = "22.05";
    packages = with pkgs; [
      i3status-rust
      tmux
      zsh
      starship
      eza
      bat
      tealdeer
      fd
      gh
      clipmenu
      delta
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
      # msmtp
      pass
      eva
      mcfly
      hexyl
      ripgrep
      autojump
      pandoc
      croc
      zathura
      go
      feh
      tree-sitter
      # nodePackages.insect
      file
      newsboat
      neovim
      # texlive.combined.scheme-full
      (texlive.combine {
        inherit
          (texlive)
          scheme-small
          latexmk
          xetex
          listings
          amsmath
          geometry
          fontspec
          hyperref
          ;
      })

      # qmk
      # qmk-udev-rules
      p7zip
      ruby
      zip

      # python packages
      # (python39.withPackages (pp:
      #   with pp; [
      #     pynvim
      #     # pandas
      #     # reticulate needs conda
      #     # conda
      #     # requests
      #     pip
      #     i3ipc
      #     ipython
      #     dbus-python
      #     html2text
      #     keymapviz
      #     # mysql-connector
      #     # pipx
      #     # pyqt5
      #     ueberzug
      #   ]))
      # https://stackoverflow.com/questions/52941074/in-nixos-how-can-i-resolve-a-collision
      # ]).override (args: { ignoreCollisions = true; }))
    ];
  };

  xdg.configFile."i3status-rust/config.toml".text = ''
    [theme]
    theme = "ctp-mocha"

    [icons]
    icons = "awesome6"
  '';
}
