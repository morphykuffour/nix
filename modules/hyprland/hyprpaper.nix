{
  pkgs,
  anyrun,
  ...
}: {
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ~/nix-config/home-manager/wallpapers/kubo.jpg
    wallpaper = DP-2,~/nix-config/home-manager/wallpapers/kubo.jpg
  '';
}
