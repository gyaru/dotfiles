_: {
  rum.desktops.hyprland = {
    enable = true;
    settings = {
      monitor = [
        "DP-1, 3440x1440@160, 0x512, 1, bitdepth, 8" # muh pixel perfect
        "HDMI-A-1, 2560x1440@60, 3440x0, 1, transform, 3, bitdepth, 8"
      ];
      exec-once = [
        "swaybg -o DP-1 -i ~/.local/share/wallpapers/bg1.jpg -m fill"
        "swaybg -o HDMI-A-1 -i ~/.local/share/wallpapers/bg2.jpg -m fill"
        "wl-paste -t text -w xclip -selection clipboard" # TODO: move this outside hyprland
      ];
      general = {
        border_size = 5;
        gaps_in = 10;
        gaps_out = 10;
        "col.active_border" = "0xFFd7827e";
        "col.inactive_border" = "0xFFea9d34";
        layout = "dwindle";
      };
      decoration = {
        shadow = {
          enabled = false;
        };
        blur = {
          enabled = false;
        };
      };
      animations = {
        enabled = false;
      };
      input = {
        kb_layout = "us,se";
        follow_mouse = 1;
        force_no_accel = true;
        repeat_delay = 250;
      };
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        vrr = 0;
      };
      dwindle = {
        pseudotile = false;
        preserve_split = "yes";
      };
      bind = [
        "SUPER, Return, exec, kitty"
        "SUPER, Space, exec, anyrun"
        "SUPER, O, exec, firefox"
        "SUPER, C, exec, hyprpicker -a"
        "SUPER SHIFT, W, killactive,"
        "SUPER SHIFT, M, exec, wlogout"
        "SUPER, F11, exec, grim -o DP-1" # fix notification
        "SUPER, F, togglefloating,"
        "SUPER, P, pseudo,"
        "SUPER, S, togglesplit," # dwindle
        # move focus with arrow keys
        "SUPER, left, movefocus, l"
        "SUPER, right, movefocus, r"
        "SUPER, up, movefocus, u"
        "SUPER, down, movefocus, d"
        # preselect with arrow keys
        "SUPER SHIFT, left, layoutmsg, preselect l"
        "SUPER SHIFT, right, layoutmsg, preselect r"
        "SUPER SHIFT, up, layoutmsg, preselect u"
        "SUPER SHIFT, down, layoutmsg, preselect d"
        # switch workspaces
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        # send active window to given workspace
        "SUPER SHIFT, 1, movetoworkspacesilent, 1"
        "SUPER SHIFT, 2, movetoworkspacesilent, 2"
        "SUPER SHIFT, 3, movetoworkspacesilent, 3"
        "SUPER SHIFT, 4, movetoworkspacesilent, 4"
        "SUPER SHIFT, 5, movetoworkspacesilent, 5"
        "SUPER SHIFT, 6, movetoworkspacesilent, 6"
        # misc
        "SUPER SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"
        ", XF86Calculator, exec, hyprctl switchxkblayout kbdfans-kbd67mkiirgb-v2 next"
      ];
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];
      bindl = [
        # volume control
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        # media
        ", XF86AudioNext, exec, playerctl next -i chromium"
        ", XF86AudioPrev, exec, playerctl previous -i chromium"
        ", XF86AudioPlay, exec, playerctl play-pause -i chromium"
      ];
      workspace = [
        "name:1, monitor:DP-1"
        "name:2, monitor:DP-1"
        "name:3, monitor:DP-1"
        "name:4, monitor:DP-1"
        "name:5, monitor:DP-1"
        "name:6, monitor:HDMI-A-1"
      ];
      windowrulev2 = [
        "float, class:org.telegram.desktop, title:Media viewer"
        "nomaxsize, title:^(Wine configuration)$"
        "minsize 899 556, class:^(battle.net.exe)$, title:^(.*Installation.*)$"
        "workspace 4, class:^(Steam)$"
        "stayfocused, title:^()$,class:^(steam)$"
        "workspace 6, class:^(obs)$"
        "workspace 6, class:^(Spotify)$"
        "workspace 5, title:^(Steam Big Picture)$"
      ];
    };
  };
}
