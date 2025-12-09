{ pkgs, lib, user, ... }:
let
  mod = "Mod1";
  local_bin = "/home/${user}/.local/bin";
  home = "/home/${user}";
in {
  wayland.windowManager.sway = {
    enable = true;
    package = pkgs.sway;
    checkConfig = false;
    config = {
      modifier = mod;
      terminal = "${pkgs.kitty}/bin/kitty";

      # Use waybar instead of swaybar
      bars = [ ];

      keybindings = {
        # Audio
        "XF86AudioMute" = "exec amixer set Master toggle";
        "XF86AudioLowerVolume" = "exec amixer set Master 4%-";
        "XF86AudioRaiseVolume" = "exec amixer set Master 4%+";
        "XF86AudioMicMute" = "exec amixer set Capture nocap";

        # Brightness
        "XF86MonBrightnessDown" = "exec brightnessctl set 4%-";
        "XF86MonBrightnessUp" = "exec brightnessctl set 4%+";

        # Apps
        "${mod}+Return" = "exec ${pkgs.kitty}/bin/kitty";
        "${mod}+Shift+d" = "exec ${pkgs.rofi}/bin/rofi -modi drun -show drun";
        "${mod}+s" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot copy area";
        "Print" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot copy output";
        "${mod}+w" = "exec ${pkgs.rofi}/bin/rofi -show window";
        "${mod}+Shift+x" = "exec systemctl suspend";
        "${mod}+Shift+q" = "kill";
        "${mod}+b" = "exec ${pkgs.brave}/bin/brave";
        "${mod}+Shift+b" = "exec sh -c \"grep -v '^#' ${home}/iCloud/bookmarks/bookmarks.txt | ${pkgs.wofi}/bin/wofi --dmenu -i -p Bookmarks | cut -d' ' -f1 | xargs -r ${pkgs.wtype}/bin/wtype\"";
        "${mod}+e" = "exec ${pkgs.emacs}/bin/emacsclient -c -a 'emacs'";
        "${mod}+d" = "exec ${pkgs.wofi}/bin/wofi --show drun";
        "Mod4+l" = "exec ${pkgs.swaylock}/bin/swaylock -f -c 000000";
        "Mod4+v" = "exec ${pkgs.clipmenu}/bin/clipmenu -i -fn Terminus:size=13 -nb '#002b36' -nf '#839496' -sb '#073642' -sf '#93a1a1'";

        # Window mgmt (same as i3)
        "${mod}+h" = "focus left";
        "${mod}+j" = "focus down";
        "${mod}+k" = "focus up";
        "${mod}+l" = "focus right";
        "${mod}+Shift+h" = "move left";
        "${mod}+Shift+j" = "move down";
        "${mod}+Shift+k" = "move up";
        "${mod}+Shift+l" = "move right";
        "${mod}+z" = "split h";
        "${mod}+Shift+backslash" = "split v";
        "${mod}+f" = "fullscreen toggle";
        "${mod}+Shift+s" = "layout stacking";
        "${mod}+Shift+w" = "layout tabbed";
        "${mod}+Shift+space" = "floating toggle";
        "${mod}+space" = "focus mode_toggle";
        "${mod}+a" = "focus parent";
        "${mod}+Tab" = "workspace back_and_forth";
        "${mod}+Page_Up" = "workspace next";
        "${mod}+Page_Down" = "workspace prev";

        "${mod}+1" = "workspace number 1";
        "${mod}+2" = "workspace number 2";
        "${mod}+3" = "workspace number 3";
        "${mod}+4" = "workspace number 4";
        "${mod}+5" = "workspace number 5";
        "${mod}+6" = "workspace number 6";
        "${mod}+7" = "workspace number 7";
        "${mod}+8" = "workspace number 8";
        "${mod}+9" = "workspace number 9";
        "${mod}+0" = "workspace number 10";
        "${mod}+Shift+1" = "move container to workspace number 1";
        "${mod}+Shift+2" = "move container to workspace number 2";
        "${mod}+Shift+3" = "move container to workspace number 3";
        "${mod}+Shift+4" = "move container to workspace number 4";
        "${mod}+Shift+5" = "move container to workspace number 5";
        "${mod}+Shift+6" = "move container to workspace number 6";
        "${mod}+Shift+7" = "move container to workspace number 7";
        "${mod}+Shift+8" = "move container to workspace number 8";
        "${mod}+Shift+9" = "move container to workspace number 9";
        "${mod}+Shift+0" = "move container to workspace number 10";

        "${mod}+Shift+c" = "reload";
        "${mod}+Shift+r" = "restart";
        "${mod}+r" = "mode resize";
      };

      modes = {
        resize = {
          "j" = "resize shrink width 10px";
          "k" = "resize grow height 10px";
          "l" = "resize shrink height 10px";
          "semicolon" = "resize grow width 10px";
          "Left" = "resize shrink width 10px";
          "Down" = "resize grow height 10px";
          "Up" = "resize shrink height 10px";
          "Right" = "resize grow width 10px";
          "Return" = "mode default";
          "Escape" = "mode default";
          "${mod}+r" = "mode default";
        };
      };

      startup = [
        { command = "exec ${pkgs.swaybg}/bin/swaybg -i ${home}/Pictures/wallpaper/wall.png -m fill"; always = true; }
        { command = "exec ${pkgs.waybar}/bin/waybar"; always = true; }
        { command = "exec kdeconnect-indicator"; always = true; }
        { command = "exec blueman-applet"; always = true; }
        { command = "exec nm-applet"; always = true; }
        # Ensure XDG portals see correct Wayland env (needed for RemoteDesktop)
        { command = "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE SWAYSOCK"; always = true; }
        { command = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway XDG_SESSION_TYPE=wayland SWAYSOCK"; always = true; }
      ];
    };
  };

  # Let system-level suspend hooks drop back to greetd; swayidle just triggers suspend
  programs.swaylock.enable = false;
  services.swayidle = {
    enable = true;
    timeouts = [
      # After 5 minutes idle, suspend the system; on resume, systemd hooks
      # terminate the user and switch to greetd (see configuration.nix).
      { timeout = 300; command = "systemctl suspend"; }
    ];
    events = [ ];
  };
}
