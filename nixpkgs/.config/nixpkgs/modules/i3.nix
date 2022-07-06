{ pkgs, lib, ... }:
let
  # variables
  mod = "Mod1";
  borderWidth = 3;

  local_bin = "/home/morp/.local/bin";
  home = "/home/morp/";
in
{
  enable = true;
  package = pkgs.i3-gaps;


  config = rec {
    bars = [ ];
    colors = {
      background = "#ffffff";

      focused = {
        background = "#285577";
        border = "#4c7899";
        childBorder = "#285577";
        indicator = "#2e9ef4";
        text = "#ffffff";
      };

      focusedInactive = {
        background = "#5f676a";
        border = "#333333";
        childBorder = "#5f676a";
        indicator = "#484e50";
        text = "#ffffff";
      };

      unfocused = {
        background = "#222222";
        border = "#333333";
        childBorder = "#222222";
        indicator = "#292d2e";
        text = "#888888";
      };

      urgent = {
        background = "#900000";
        border = "#2f343a";
        childBorder = "#900000";
        indicator = "#900000";
        text = "#ffffff";
      };

      placeholder = {
        # indicator and border are ignored
        background = "#0c0c0c";
        border = "#000000";
        childBorder = "#0c0c0c";
        indicator = "#000000";
        text = "#ffffff";
      };
    };
    window.border = 2;
    fonts = {
      names = [ "Noto Sans" ];
      size = 9.0;
    };
    gaps = {
      inner = 20;
      outer = 5;
    };

    # Use Mouse+$mod to drag floating windows to their wanted position
    # floating_modifier = ${mod};

    keybindings = lib.mkOptionDefault {
      "XF86AudioMute" = "exec amixer set Master toggle";
      "XF86AudioLowerVolume" = "exec amixer set Master 4%-";
      "XF86AudioRaiseVolume" = "exec amixer set Master 4%+";
      "XF86MonBrightnessDown" = "exec brightnessctl set 4%-";
      "XF86MonBrightnessUp" = "exec brightnessctl set 4%+";
      "${mod}+Return" = "exec ${pkgs.kitty}/bin/kitty";
      "${mod}+d" = "exec ${pkgs.rofi}/bin/rofi -modi drun -show drun";
      "${mod}+Shift+w" = "exec ${pkgs.rofi}/bin/rofi -show window";
      "${mod}+b" = "exec ${pkgs.brave}/bin/brave";
      "${mod}+Shift+x" = "exec systemctl suspend";

      "${mod}+h" = "focus left";
      "${mod}+j" = "focus down";
      "${mod}+k" = "focus up";
      "${mod}+l" = "focus right";

      "${mod}+Shift+h" = "move left";
      "${mod}+Shift+j" = "move down";
      "${mod}+Shift+k" = "move up";
      "${mod}+Shift+l" = "move right";

      # run scripts TODO move to sxhkd when working
      # "${mod}+ g" = "exec --no-startup-id ${local_bin}/google-search.sh";
      # "${mod}+ 0" = "exec --no-startup-id ${local_bin}/nixpkg-search.sh";

      # "${mod} + shift + n" = "$TERMINAL sudo nmtui";
      "${mod} + shift + n" = "exec termite -e ${local_bin}/notetaker -t notetaker_window";

      # layouts
      # "${mod} + shift + h" = "layout split h";
      # "${mod} + shift + v" = "layout split v";

      # split in horizontal orientation
      "${mod}+z" = "split h";

      # split in vertical orientation
      "${mod}+x" = "split v";

      # Use KDE logoff screen TODO fix
      # "${mod}+Shift+e" = "exec --no-startup-id qdbus org.kde.ksmserver /KSMServer org.kde.KSMServerInterface.logout -1 -1 -1";
    };

    startup = [
      {
        command = "exec i3-msg workspace 1";
        always = true;
        notification = false;
      }
      {
        command = "exec sxhkd";
        always = true;
        notification = false;
      }
      {
        command = "kdeconnect-indicator";
        always = true;
        notification = false;
      }
      {
        command = "blueman-applet";
        always = true;
        notification = false;
      }
      {
        command = "${pkgs.feh}/bin/feh --bg-scale --randomize ~/Pictures/wallpapers/*";
        always = true;
        notification = false;
      }
      # {
      #   command = "${home}/.config/polybar/launch.sh";
      #   always = true;
      #   notification = false;
      # }
    ];

  };

  extraConfig = ''
      # Start i3bar to display a workspace bar (plus the system information i3status
      # finds out, if available)
      bar {
              status_command i3status
              tray_output primary
              font -misc-fixed-medium-r-normal--13-120-75-75-C-70-iso10646-1
              font pango:Jetbrains Mono 15
      }
    for_window [ title="notetaker_window" ] floating enable

  '';
}


# bindsym --release $mod+x exec --no-startup-id rofi -lines 10 -padding 0 -show search -modi search:~/bin/rofi-web-search.py -i -p "Search: "

#       bindsym ${mod}+ g = "exec --no-startup-id ${local_bin}/google-search.sh";
#       bindsym ${mod}+ home = "exec --no-startup-id ${local_bin}/nixpkg-search.sh";

# floating_modifier = Mod4
# # toggle tiling / floating
# bindsym $mod+Shift+space floating toggle

# # google search
# bindsym $mod+g exec --no-startup-id ~/.local/bin/google-search.sh

# # kill window
# bindsym $mod+Shift+q kill

# # resize window (you can also use the mouse for that)
# mode "resize" {
#       # These bindings trigger as soon as you enter the resize mode
#       bindsym h resize shrink width 10 px or 10 ppt
#       bindsym j resize grow height 10 px or 10 ppt
#       bindsym k resize shrink height 10 px or 10 ppt
#       bindsym l resize grow width 10 px or 10 ppt

#       # same bindings, but for the arrow keys
#       bindsym Left resize shrink width 10 px or 10 ppt
#       bindsym Down resize grow height 10 px or 10 ppt
#       bindsym Up resize shrink height 10 px or 10 ppt
#       bindsym Right resize grow width 10 px or 10 ppt

#       # back to normal: Enter or Escape
#       bindsym Return mode "default"
#       bindsym Escape mode "default"
# }
# {
#   command = "systemctl --user restart polybar.service";
#   always = true;
#   notification = false;
# }

# bindsym $mod+r mode "resize"
