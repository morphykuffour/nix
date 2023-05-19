# https://wiki.hyprland.org/Nix/Hyprland-on-NixOS/
{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
  services.xserver = {
    enable = true;
    # videosDrivers = ["nvidia"];
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
  };

  hardware = {
    opengl.enable = true;
    nvidia.modesetting.enable = true;
  };

  # hyprland
  programs = {
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.default;
      xwayland.enable = true;
    };
  };
}