# Centralized wallpaper management for multiple desktop environments
# Works with: i3, Sway, XFCE, Plasma6 (with Fakwin), and any X11/Wayland compositor
{
  pkgs,
  lib,
  user,
  config,
  ...
}: let
  wallpaperPath = "/home/${user}/Pictures/wallpaper/wall.jpg";

  # Script to set wallpaper across all active environments
  setWallpaperScript = pkgs.writeShellScriptBin "set-wallpaper" ''
    WALLPAPER="${wallpaperPath}"

    # Check if a custom path is provided
    if [ -n "$1" ]; then
      WALLPAPER="$1"
    fi

    # X11: Use feh (works for i3, XFCE without xfdesktop, Plasma with Fakwin)
    if [ -n "$DISPLAY" ]; then
      ${pkgs.feh}/bin/feh --no-fehbg --bg-fill "$WALLPAPER" 2>/dev/null || true
    fi

    # XFCE: Set via xfconf if xfdesktop is running
    if ${pkgs.procps}/bin/pgrep -x xfdesktop >/dev/null 2>&1; then
      # Get all monitors and set wallpaper for each
      for monitor in $(${pkgs.xfce.xfconf}/bin/xfconf-query -c xfce4-desktop -l | grep -E '/backdrop/screen.*/monitor.*/workspace.*/last-image$' | head -10); do
        ${pkgs.xfce.xfconf}/bin/xfconf-query -c xfce4-desktop -p "$monitor" -s "$WALLPAPER" 2>/dev/null || true
      done
      # Also set for any new monitors that might be added
      ${pkgs.xfce.xfconf}/bin/xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorVirtual1/workspace0/last-image -n -t string -s "$WALLPAPER" 2>/dev/null || true
    fi

    # Wayland/Sway: swaymsg if running under Sway
    if [ -n "$SWAYSOCK" ]; then
      ${pkgs.sway}/bin/swaymsg output "*" bg "$WALLPAPER" fill 2>/dev/null || true
    fi

    # Hyprland: hyprctl if running
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
      ${pkgs.hyprpaper}/bin/hyprctl hyprpaper wallpaper ",$WALLPAPER" 2>/dev/null || true
    fi

    echo "Wallpaper set to: $WALLPAPER"
  '';
in {
  home.packages = [setWallpaperScript];

  # Ensure wallpaper directory exists
  home.file."Pictures/wallpaper/.keep".text = "";

}
