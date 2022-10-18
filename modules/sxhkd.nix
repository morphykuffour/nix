let
  # user scripts
  local_bin = "~/.local/bin";
in {
  services.sxhkd = {
    enable = true;
    keybindings = {
      # "alt + Return" = "$TERMINAL";
      # "alt + r" = "$TERMINAL -e $FILE";

      # COPY system-wide
      # "super + c" = "xclip -selection primary -o | xclip -selection clipboard -i";

      # PASTE system-wide
      # "super + v" = "sh -c 'xclip -selection clipboard -o | xvkbd -xsendevent -file - 2>/dev/null'";

      # "alt + g" = "${local_bin}/google-search.sh";

      # "super + shift + a" = "$TERMINAL -e alsamixer; pkill -RTMIN+10 blocks";

      "alt + shift + n" = "$TERMINAL -e sudo nmtui";

      "alt +  b" = "$BROWSER";

      # "super + shift + s" = "~/.local/bin/xps-display-only-layout.sh";
      # "super + shift + d" = "~/.local/bin/dual-display-layout.sh";

      # reload sxhkd
      "alt + Escape" = "pkill -USR1 -x sxhkd";

      # play/pause
      "{Pause,XF86AudioPlay}" = "playerctl play-pause";

      # next/prev song
      "XF86AudioPrev" = "playerctl previous";
      "XF86AudioNext " = "playerctl next";

      # display brightness
      "{XF86MonBrightnessUp,XF86KbdBrightnessUp}" = "xbacklight -dec 15";
      "{XF86MonBrightnessDown,XF86KbdBrightnessDown}" = "xbacklight -inc 15";

      # toggle repeat/shuffle
      # "super + alt + {r,z}" = "playerctl {loop,shuffle}";

      # Take screenshot
      "alt + s" = "flameshot gui --path $HOME/Pictures/screenshots --filename image-$(date '+%y%m%d-%H%M-%S').png";

      # my-take-on.tech #
      # Show clipmenu
      "super + v" = "CM_LAUNCHER=rofi clipmenu \
        -location 1 \
        -m -3 \
        -no-show-icons \
        -theme-str '* \{ font: 10px; \}' \
        -theme-str 'listview \{ spacing: 0; \}' \
        -theme-str 'window \{ width: 20em; \}'";
    };
  };
}
