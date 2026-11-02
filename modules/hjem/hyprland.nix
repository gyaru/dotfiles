{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  inherit (lib.meta) getExe getExe';
in {
  packages = with pkgs; [
    anyrun
    grim
    hyprpicker
    playerctl
    slurp
    swaybg
    wl-clipboard
    wlogout
    xclip
  ];

  xdg.config.files."hypr/hyprland.lua".text =
    /*
    lua
    */
    ''
      hl.monitor({ output = "DP-1", mode = "3440x1440@160", position = "0x512", scale = 1, bitdepth = 8 })
      hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@60", position = "3440x0", scale = 1, transform = 3, bitdepth = 8 })

      hl.on("hyprland.start", function()
        hl.exec_cmd("${getExe pkgs.swaybg} --output DP-1 --image ~/.local/share/wallpapers/bg1.jpg --mode fill")
        hl.exec_cmd("${getExe pkgs.swaybg} --output HDMI-A-1 --image ~/.local/share/wallpapers/bg2.jpg --mode fill")
        hl.exec_cmd("${getExe' pkgs.wl-clipboard "wl-paste"} --type text --watch ${getExe pkgs.xclip} -selection clipboard")
      end)

      hl.config({
        general = {
          border_size = 5,
          gaps_in = 10,
          gaps_out = 10,
          col = { active_border = "rgba(d7827eff)", inactive_border = "rgba(ea9d34ff)" },
          layout = "dwindle",
        },
        decoration = { shadow = { enabled = false }, blur = { enabled = false } },
        animations = { enabled = false },
        input = { kb_layout = "us,se", follow_mouse = 1, force_no_accel = true, repeat_delay = 250 },
        misc = { disable_hyprland_logo = true, disable_splash_rendering = true, vrr = 0 },
        dwindle = { preserve_split = true },
      })

      hl.bind("SUPER + Return", hl.dsp.exec_cmd("${getExe pkgs.kitty}"))
      hl.bind("SUPER + Space", hl.dsp.exec_cmd("${getExe pkgs.anyrun}"))
      hl.bind("SUPER + O", hl.dsp.exec_cmd("${getExe pkgs.firefox-bin}"))
      hl.bind("SUPER + C", hl.dsp.exec_cmd("${getExe pkgs.hyprpicker} --autocopy"))
      hl.bind("SUPER + SHIFT + W", hl.dsp.window.close())
      hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("${getExe pkgs.wlogout}"))
      hl.bind("SUPER + F11", hl.dsp.exec_cmd("${getExe pkgs.grim} -o DP-1"))
      hl.bind("SUPER + F", hl.dsp.window.float({ action = "toggle" }))
      hl.bind("SUPER + P", hl.dsp.window.pseudo())
      hl.bind("SUPER + S", hl.dsp.layout("togglesplit"))

      for _, direction in ipairs({ "left", "right", "up", "down" }) do
        hl.bind("SUPER + " .. direction, hl.dsp.focus({ direction = direction }))
        hl.bind("SUPER + SHIFT + " .. direction, hl.dsp.layout("preselect " .. direction:sub(1, 1)))
      end

      for i = 1, 6 do
        hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
        hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i, follow = false }))
        hl.workspace_rule({ workspace = tostring(i), monitor = i == 6 and "HDMI-A-1" or "DP-1" })
      end

      hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd('${getExe pkgs.grim} -g "$(${getExe pkgs.slurp})" - | ${getExe' pkgs.wl-clipboard "wl-copy"}'))
      hl.bind("XF86Calculator", hl.dsp.exec_cmd("${getExe' osConfig.programs.hyprland.package "hyprctl"} switchxkblayout kbdfans-kbd67mkiirgb-v2 next"))
      hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
      hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("${getExe' pkgs.wireplumber "wpctl"} set-volume --limit 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true })
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("${getExe' pkgs.wireplumber "wpctl"} set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true })
      hl.bind("XF86AudioNext", hl.dsp.exec_cmd("${getExe pkgs.playerctl} next --ignore-player chromium"), { locked = true })
      hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("${getExe pkgs.playerctl} previous --ignore-player chromium"), { locked = true })
      hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("${getExe pkgs.playerctl} play-pause --ignore-player chromium"), { locked = true })

      hl.window_rule({ name = "telegram-media", match = { class = "org.telegram.desktop", title = "Media viewer" }, float = true })
      hl.window_rule({ name = "wine-config", match = { title = "^(Wine configuration)$" }, no_max_size = true })
      hl.window_rule({ name = "battle-net-installer", match = { class = "^(battle.net.exe)$", title = "^(.*Installation.*)$" }, min_size = { 899, 556 } })
      hl.window_rule({ name = "steam-workspace", match = { class = "^(Steam)$" }, workspace = "4" })
      hl.window_rule({ name = "steam-popup", match = { class = "^(steam)$", title = "^$" }, stay_focused = true })
      hl.window_rule({ name = "obs-workspace", match = { class = "^(obs)$" }, workspace = "6" })
      hl.window_rule({ name = "spotify-workspace", match = { class = "^(Spotify)$" }, workspace = "6" })
      hl.window_rule({ name = "steam-big-picture", match = { title = "^(Steam Big Picture)$" }, workspace = "5" })
    '';
}
