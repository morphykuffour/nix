{ pkgs, lib, ... }:
let
  # variables
  mod = "Mod1";
  borderWidth = 3;

  local_bin = "/home/morp/.local/bin";
  home = "/home/morp/";
in
{
  # config = lib.mkIf config.my.gui-programs {
  xsession.windowManager.i3 = {
    enable = true;
    package = pkgs.i3-gaps;

    config = {

      bars = [{
        statusCommand = "${pkgs.i3status}/bin/i3status";
        position = "bottom";
      }];

      modifier = mod;
      terminal = "${pkgs.kitty}/bin/kitty";
      # fonts = {
      #   names = [ "pango:DejaVu Sans Mono" ];
      #   size = 13.0;
      # };

      fonts = {
        names = [ "Noto Sans" ];
        size = 15.0;
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
            criteria = { window_role = "pop-up"; };
            command = "floating enable";
          }
        ];
        border = 2;
      };
      gaps = {
        inner = 20;
        outer = 5;
      };

      # Use Mouse+$mod to drag floating windows to their wanted position
      # floating_modifier = ${mod};

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
        "${mod}+w" = "exec ${pkgs.rofi}/bin/rofi -show window";
        "${mod}+Shift+x" = "exec systemctl suspend";
        "${mod}+Shift+q" = "kill";
        "${mod}+b" = "exec ${pkgs.brave}/bin/brave";
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
        "${mod}+x" = "split v";
        "${mod}+f" = "fullscreen toggle";
        "${mod}+Shift+s" = "layout stacking";
        "${mod}+Shift+w" = "layout tabbed";
        "${mod}+e" = "layout toggle split";
        "${mod}+Shift+space" = "floating toggle";
        "${mod}+space" = "focus mode_toggle";
        "${mod}+a" = "focus parent";
        "${mod}+1" = "workspace 1: nvim";
        "${mod}+2" = "workspace 2: browsing";
        "${mod}+3" = "workspace 3: comms";
        "${mod}+4" = "workspace number 4";
        "${mod}+5" = "workspace number 5";
        "${mod}+6" = "workspace number 6";
        "${mod}+7" = "workspace number 7";
        "${mod}+8" = "workspace number 8";
        "${mod}+9" = "workspace number 9: game";
        "${mod}+0" = "workspace 10: video";
        "${mod}+Shift+1" = "move container to workspace 1: nvim";
        "${mod}+Shift+2" = "move container to workspace 2: browsing";
        "${mod}+Shift+3" = "move container to workspace 3: comms";
        "${mod}+Shift+4" = "move container to workspace number 4";
        "${mod}+Shift+5" = "move container to workspace number 5";
        "${mod}+Shift+6" = "move container to workspace number 6";
        "${mod}+Shift+7" = "move container to workspace number 7";
        "${mod}+Shift+8" = "move container to workspace number 8";
        "${mod}+Shift+9" = "move container to workspace number 9: game";
        "${mod}+Shift+0" = "move container to workspace 10: video";
        "${mod}+Shift+c" = "reload";
        "${mod}+Shift+r" = "restart";
        "${mod}+Shift+e" = ''exec "${pkgs.i3}/bin/i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' '${pkgs.i3}/bin/i3-msg exit'"'';
        "${mod}+r" = ''mode "resize"'';
        # "${mod}+p" = "exec /home/dave/bin/layout _interactive";

        "${mod} + shift + n" = "exec termite -e ${local_bin}/notetaker -t notetaker_window";

        # run scripts TODO move to sxhkd when working
        # "${mod}+ g" = "exec --no-startup-id ${local_bin}/google-search.sh";
        # "${mod}+ 0" = "exec --no-startup-id ${local_bin}/nixpkg-search.sh";

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
          command = "${home}/.config/polybar/launch.sh";
          always = true;
          notification = false;
        }
        # {
        #   command = "exec sxhkd";
        #   always = true;
        #   notification = false;
        # }
      ];
    };

    extraConfig = ''
      for_window [ title="notetaker_window" ] floating enable
      title_align center
      assign [class="nvim"] "1: nvim"
      assign [class="kitty" title="^\[mosh\] "] "3: comms"
      assign [class=".obs-wrapped"] "8: obs"
      assign [class="Steam"] "9: game"

      # Start i3bar to display a workspace bar (plus the system informatio i3status
      # finds out, if available)
      bar {
              status_command i3status
              tray_output primary
              font -misc-fixed-medium-r-normal--13-120-75-75-C-70-iso10646-1
              font pango:Jetbrains Mono 15
      }

      # workspace "1: emacs" output DisplayPort-0
      # workspace "2: browsing" output DisplayPort-1
      # workspace "3: comms" output DisplayPort-2
      # workspace "10: video" output HDMI-A-0

    '';
  };

  # };
}
