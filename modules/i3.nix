{
  pkgs,
  lib,
  ...
}: let
  # variables
  mod = "Mod1";
  local_bin = "/home/morp/.local/bin";
  home = "/home/morp/";
in {
  xsession.windowManager.i3 = {
    enable = true;
    package = pkgs.i3-gaps;

    config = {
      modifier = mod;
      terminal = "${pkgs.kitty}/bin/kitty";
      fonts = {
        names = ["Noto Sans"];
        size = 9.0;
      };

      modes = {
        resize = {
          "j" = "resize shrink width 10 px or 10 ppt";
          "k" = "resize grow height 10 px or 10 ppt";
          "l" = "resize shrink height 10 px or 10 ppt";
          "semicolon" = "resize grow width 10 px or 10 ppt";
          "Left" = "resize shrink width 10 px or 10 ppt";
          "Down" = "resize grow height 10 px or 10 ppt";
          "Up" = "resize shrink height 10 px or 10 ppt";
          "Right" = "resize grow width 10 px or 10 ppt";
          "Return" = ''mode "default"'';
          "Escape" = ''mode "default"'';
          "${mod}+r" = ''mode "default"'';
        };
      };

      window = {
        commands = [
          {
            criteria = {window_role = "pop-up";};
            command = "floating enable";
          }
        ];
        border = 3;
      };

      gaps = {
        inner = 2;
        outer = 2;
      };

      keybindings = {
        # Audio keybindings
        "XF86AudioMute" = "exec amixer set Master toggle";
        "XF86AudioLowerVolume" = "exec amixer set Master 4%-";
        "XF86AudioRaiseVolume" = "exec amixer set Master 4%+";
        "XF86AudioMicMute" = "exec  amixer set Capture nocap";

        # Screen keybindings
        "XF86MonBrightnessDown" = "exec brightnessctl set 4%-";
        "XF86MonBrightnessUp" = "exec brightnessctl set 4%+";

        # Application keybindings
        "${mod}+Return" = "exec ${pkgs.kitty}/bin/kitty";
        "${mod}+Shift+d" = "exec ${pkgs.rofi}/bin/rofi -modi drun -show drun";
        "${mod}+s" = "exec flameshot gui --clipboard --path ${home}/Dropbox/screenshots/";
        "Print" = "exec flameshot full --clipboard --path ${home}/Dropbox/screenshots/";
        "${mod}+w" = "exec ${pkgs.rofi}/bin/rofi -show window";
        "${mod}+Shift+x" = "exec systemctl suspend";
        "${mod}+Shift+q" = "kill";
        "${mod}+b" = "exec ${pkgs.brave}/bin/brave";
        # "${mod}+y"       = "exec ${pkgs.emacs}/bin/emacs";
        "${mod}+d" = "exec ${pkgs.dmenu}/bin/dmenu_run";
        "Mod4+l" = "exec ${pkgs.systemd}/bin/loginctl lock-session";
        "Mod4+v" = "exec ${pkgs.clipmenu}/bin/clipmenu -i -fn Terminus:size=13 -nb '#002b36' -nf '#839496' -sb '#073642' -sf '#93a1a1'";

        # i3 window management
        "${mod}+h" = "focus left";
        "${mod}+j" = "focus down";
        "${mod}+k" = "focus up";
        "${mod}+l" = "focus right";
        "${mod}+Shift+h" = "move left";
        "${mod}+Shift+j" = "move down";
        "${mod}+Shift+k" = "move up";
        "${mod}+Shift+l" = "move right";
        "${mod}+z" = "split h";
        "${mod}+|" = "split v";
        "${mod}+f" = "fullscreen toggle";
        "${mod}+Shift+s" = "layout stacking";
        "${mod}+Shift+w" = "layout tabbed";
        "${mod}+e" = "layout toggle split";
        "${mod}+Shift+space" = "floating toggle";
        "${mod}+space" = "focus mode_toggle";
        "${mod}+a" = "focus parent";
        "${mod}+Tab"="workspace back_and_forth";
        "${mod}+Prior" = "workspace next";
        "${mod}+Next"  = "workspace prev";

        # TODO: figure out
        # bindsym $mod+[ workspace prev
        # bindsym $mod+] workspace next

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
        "${mod}+Shift+e" = ''exec "${pkgs.i3}/bin/i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' '${pkgs.i3}/bin/i3-msg exit'"'';
        "${mod}+r" = ''mode "resize"'';

        "${mod}+Shift+n" = "exec kitty --title notetaker_window --config ${home}/.config/kitty/notetaker.conf ${local_bin}/notetaker";
        "${mod}+Shift+m" = "exec kitty --title floatimage_window ${local_bin}/floatimage";

        # run scripts TODO move to sxhkd when working
        "${mod}+ g" = "exec --no-startup-id ${local_bin}/google-search.sh";
        "${mod}+ Shift + g" = "exec --no-startup-id ${local_bin}/nixpkg-search.sh";
      };

      startup = [
        {
          command = "exec i3-msg workspace 1";
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
          command = "flameshot";
          always = true;
          notification = false;
        }
        {
          command = "${pkgs.feh}/bin/feh --bg-scale --randomize ~/Pictures/wallpapers/*";
          always = true;
          notification = false;
        }
        {
          command = "nm-applet";
          always = true;
          notification = false;
        }
        {
          command = "exec sxhkd -c /home/morp/.config/sxhkd/sxhkdrc";
          always = true;
          notification = false;
        }
        {
          command = "${home}/.config/polybar/launch.sh";                                                                                     
          always = true;                                                                                                                     
          notification = false;                                                                                                              
        }  
      ];
    };

    extraConfig = ''
      for_window [ title="notetaker_window" ] floating enable resize set 640 480
      title_align center
      for_window [ title="floatimage_window" ] floating enable resize set 640 260
      title_align center

      # class                   border  backgr. text    indicator child_border
      client.focused            #ffdb01 #ffdb01 #0000ff #ffdb01   #ffdb01
      # i3 v4.21
      client.focused_tab_title  #ffdb01 #0125ff #0000ff #ffdb01   #ffdb01
      client.focused_inactive   #333333 #5f676a #ffffff #484e50   #5f676a

    '';
  };
}
      # bindsym $mod+[ workspace prev
      # bindsym $mod+] workspace next
