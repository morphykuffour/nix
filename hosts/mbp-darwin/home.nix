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
  };

  home = {
    username = "morph";
    stateVersion = "22.05";

    shellAliases = {
      zathura = "open -a Zathura";
    };

    packages = with pkgs; [
      p7zip
      unar
      ripgrep
      autojump
      pandoc
      croc
      starship
      tealdeer
      jupyter
      ranger
      stylua
      cscope
      delta
      tmux
      kitty
      ruby
      edir
      curl
      zsh
      eza
      fzf
      bat
      fd
      gh
      jq
      rage
      deadnix
      neovim
      todoist
      qrcp
    ];
  };
}
