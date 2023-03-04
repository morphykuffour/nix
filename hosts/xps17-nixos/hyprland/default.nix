{ config
, pkgs
, lib
, user
, ...
}: {
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = import ./hyprland.nix { inherit user pkgs; };
  };
}
