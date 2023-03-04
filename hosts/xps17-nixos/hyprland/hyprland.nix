{ pkgs, user, ... }:
''
# startup
    exec-once = wl-clipboard-history -t
    exec-once = ~/.config/hypr/xdg-portal-hyprland
    exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
    exec-once = wlsunset -S 9:00 -s 19:30
    exec = swaybg -m fill -i ~/.wallpapers/wallhaven-gp89we.jpg
    exec-once = waybar

# monitor setup
    monitor=,preferred,auto,1

# keyboard setup
    input {
      kb_layout = us
      follow_mouse = 1
      sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
    }

# general
    general {
      gaps_in=5
      gaps_out=5
      border_size=0
      no_border_on_floating = true
      layout = dwindle
    }

# misc
    misc {
      disable_hyprland_logo = true
      disable_splash_rendering = true
      mouse_move_enables_dpms = true
      no_vfr = false
      enable_swallow = true
      swallow_regex = ^(wezterm)$
    }

# decoration

    decoration {
      rounding = 8
      multisample_edges = true

      active_opacity = 1.0
      inactive_opacity = 1.0

      blur = true
      blur_size = 3
      blur_passes = 3
      blur_new_optimizations = true

      drop_shadow = true
      shadow_ignore_window = true
      shadow_offset = 2 2
      shadow_range = 4
      shadow_render_power = 2
      col.shadow = 0x66000000

      blurls = gtk-layer-shell
      # blurls = waybar
      blurls = lockscreen
    }

# animations
    animations {
      enabled = true
      bezier = overshot, 0.05, 0.9, 0.1, 1.05
      bezier = smoothOut, 0.36, 0, 0.66, -0.56
      bezier = smoothIn, 0.25, 1, 0.5, 1

      animation = windows, 1, 5, overshot, slide
      animation = windowsOut, 1, 4, smoothOut, slide
      animation = windowsMove, 1, 4, default
      animation = border, 1, 10, default
      animation = fade, 1, 10, smoothIn
      animation = fadeDim, 1, 10, smoothIn
      animation = workspaces, 1, 6, default

    }

# layouts

    dwindle {
      no_gaps_when_only = false
      pseudotile = true # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
      preserve_split = true # you probably want this
    }

# window rules
    windowrule = float, file_progress
    windowrule = float, confirm
    windowrule = float, dialog
    windowrule = float, download
    windowrule = float, notification
    windowrule = float, error
    windowrule = float, splash
    windowrule = float, confirmreset
    windowrule = float, title:Open File
    windowrule = float, title:branchdialog
    windowrule = float, Lxappearance
    windowrule = float, Rofi
    windowrule = animation none,Rofi
    windowrule = float,viewnior
    windowrule = float,feh
    windowrule = float, pavucontrol-qt
    windowrule = float, pavucontrol
    windowrule = float, file-roller
    windowrule = fullscreen, wlogout
    windowrule = float, title:wlogout
    windowrule = fullscreen, title:wlogout
    windowrule = idleinhibit focus, mpv
    windowrule = idleinhibit fullscreen, firefox
    windowrule = float, title:^(Media viewer)$
    windowrule = float, title:^(Volume Control)$
    windowrule = float, title:^(Picture-in-Picture)$
    windowrule = size 800 600, title:^(Volume Control)$
    windowrule = move 75 44%, title:^(Volume Control)$

# keybindings

    bind = SUPER, B, exec, brave
    bind = SUPER, L, exec, /home/titus/w11
    bind = SUPER, P, exec, wlogout
    bind = SUPER, F1, exec, ~/.config/hypr/keybind

# multimedia
    binde=, XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
    binde=, XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    binde=, XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    bind=, XF86AudioPlay, exec, playerctl play-pause
    bind=, XF86AudioPause, exec, playerctl play-pause
    bind=, XF86AudioNext, exec, playerctl next
    bind=, XF86AudioPrev, exec, playerctl previous

# Screenshot
    $screenshotarea = hyprctl keyword animation "fadeOut,0,0,default"; grimblast --notify copysave area; hyprctl keyword animation "fadeOut,1,4,default"
    bind = SUPER SHIFT, S, exec, $screenshotarea
    bind = , Print, exec, grimblast --notify --cursor copysave output
    bind = ALT, Print, exec, grimblast --notify --cursor copysave screen

# misc
    bind = SUPER SHIFT, X, exec, hyprpicker -a -n
    bind = CTRL ALT, L, exec, swaylock
    bind = SUPER, Return, exec, ${pkgs.kitty}/bin/kitty
    bind = SUPER, X, exec, kitty
    bind = SUPER, E, exec, ${pkgs.thunar}/bin/thunar
    bind = SUPER, R, exec, killall rofi || rofi -show drun -theme ~/.config/rofi/global/rofi.rasi
    bind = SUPER, period, exec, killall rofi || rofi -show emoji -emoji-format "{emoji}" -modi emoji -theme ~/.config/rofi/global/emoji
    bind = SUPER, escape, exec, wlogout --protocol layer-shell -b 5 -T 400 -B 400

# window management
    bind = SUPER, Q, killactive,
    bind = SUPER SHIFT, Q, exit,
    bind = SUPER, F, fullscreen,
    bind = SUPER, Space, togglefloating,
    bind = SUPER, P, pseudo, # dwindle
    bind = SUPER, S, togglesplit, # dwindle

# bind=,Print,exec,grim $(xdg-user-dir PICTURES)/Screenshots/$(date +'%Y%m%d%H%M%S_1.png') && notify-send 'Screenshot Saved'
# bind=SUPER,Print,exec,grim - | wl-copy && notify-send 'Screenshot Copied to Clipboard'
# bind=SUPERSHIFT,Print,exec,grim - | swappy -f -
# bind=SUPERSHIFT,S,exec,slurp | grim -g - $(xdg-user-dir PICTURES)/Screenshots/$(date +'%Y%m%d%H%M%S_1.png') && notify-send 'Screenshot Saved'

# focusing on windows
    bind = SUPER, left, movefocus, l
    bind = SUPER, right, movefocus, r
    bind = SUPER, up, movefocus, u
    bind = SUPER, down, movefocus, d

# move windows
    bind = SUPER SHIFT, left, movewindow, l
    bind = SUPER SHIFT, right, movewindow, r
    bind = SUPER SHIFT, up, movewindow, u
    bind = SUPER SHIFT, down, movewindow, d

# resizing windows
    bind = SUPER CTRL, left, resizeactive, -20 0
    bind = SUPER CTRL, right, resizeactive, 20 0
    bind = SUPER CTRL, up, resizeactive, 0 -20
    bind = SUPER CTRL, down, resizeactive, 0 20

# tabbed workspaces
    bind= SUPER, g, togglegroup
    bind= SUPER, tab, changegroupactive

# special keybindings
    bind = SUPER, grave, togglespecialworkspace
    bind = SUPERSHIFT, grave, movetoworkspace, special

# switch workspaces
    bind = SUPER, 1, workspace, 1
    bind = SUPER, 2, workspace, 2
    bind = SUPER, 3, workspace, 3
    bind = SUPER, 4, workspace, 4
    bind = SUPER, 5, workspace, 5
    bind = SUPER, 6, workspace, 6
    bind = SUPER, 7, workspace, 7
    bind = SUPER, 8, workspace, 8
    bind = SUPER, 9, workspace, 9
    bind = SUPER, 0, workspace, 10
    bind = SUPER ALT, up, workspace, e+1
    bind = SUPER ALT, down, workspace, e-1

# workspaces
    bind = SUPER SHIFT, 1, movetoworkspace, 1
    bind = SUPER SHIFT, 2, movetoworkspace, 2
    bind = SUPER SHIFT, 3, movetoworkspace, 3
    bind = SUPER SHIFT, 4, movetoworkspace, 4
    bind = SUPER SHIFT, 5, movetoworkspace, 5
    bind = SUPER SHIFT, 6, movetoworkspace, 6
    bind = SUPER SHIFT, 7, movetoworkspace, 7
    bind = SUPER SHIFT, 8, movetoworkspace, 8
    bind = SUPER SHIFT, 9, movetoworkspace, 9
    bind = SUPER SHIFT, 0, movetoworkspace, 10

# mouse bindings
    bindm = SUPER, mouse:272, movewindow
    bindm = SUPER, mouse:273, resizewindow
    bind = SUPER, mouse_down, workspace, e+1
    bind = SUPER, mouse_up, workspace, e-1
''
