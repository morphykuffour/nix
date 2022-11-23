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
    # ./modules/nvim.nix
    # TODO make tailscale work
    # ./modules/tailscale.nix
    ./modules/picom.nix
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

  nixpkgs.config.allowUnfree = true;

  home = {
    username = "morp";
    homeDirectory = "/home/morp";
    stateVersion = "22.05";
    packages = (import ./packages.nix) { inherit pkgs; };
  };
}
