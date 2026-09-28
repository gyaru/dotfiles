{inputs, ...}: {
  flake.modules.hjem.noctalia = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.options) mkOption;
    inherit (lib.lists) optionals singleton;
    inherit (lib.types) bool;
  in {
    imports = singleton inputs.noctalia.hjemModules.default;

    options.programs.noctalia.laptop = mkOption {
      type = bool;
      default = false;
      description = "Whether to show laptop-specific Noctalia widgets.";
    };

    config = {
      packages = with pkgs; [
        jq
        mpv
        mpvpaper
        socat
        tailscale
        xdg-utils
      ];

      programs.noctalia = {
        enable = true;

        systemd.enable = true;

        settings = {
          shell = {
            corner_radius_scale = 0;
            animation.enabled = false;
          };

          bar.main = {
            border = "hover";
            border_width = 2.0;
            capsule = true;
            capsule_opacity = 0.0;
            capsule_radius = 0;
            capsule_thickness = 0.8;
            concave_edge_corners = false;
            font_family = "Maple Mono NF";
            font_scale = 0.93;
            font_weight = 400;
            margin_ends = 0;
            radius = 0;
            radius_bottom_left = 0;
            radius_bottom_right = 0;
            radius_top_left = 0;
            radius_top_right = 0;
            thickness = 27;
            start = singleton "control-center";
            center = ["workspaces" "luochen1990/niri-ribbon:ribbon"];
            end =
              [
                "clock"
                "media"
                "tray"
                "davemhammer/tailscale:status"
                "notifications"
                "clipboard"
                "bluetooth"
                "volume"
                "session"
              ]
              ++ optionals config.programs.noctalia.laptop [
                "network"
                "brightness"
                "battery"
              ];
            monitor.wisecoco = {
              match = "HDMI-A-1";
              enabled = false;
            };
          };

          control_center.shortcuts = [
            {type = "bluetooth";}
            {type = "caffeine";}
            {type = "nightlight";}
            {type = "power_profile";}
          ];

          desktop_widgets.enabled = false;

          lockscreen_widgets.enabled = false;

          plugins = {
            enabled = [
              "noctalia/mpvpaper"
              "davemhammer/tailscale"
              "luochen1990/niri-ribbon"
            ];
            auto_update = "none";
            source = [
              {
                name = "official";
                kind = "git";
                location = "https://github.com/noctalia-dev/official-plugins";
                enabled = true;
              }
              {
                name = "community";
                kind = "git";
                location = "https://github.com/noctalia-dev/community-plugins";
                enabled = true;
              }
            ];
          };

          theme = {
            builtin = "Rosé Pine";
            community_palette = "Rose Pine Moon";
            mode = "light";
            shell_mode = "light";
          };

          widget = {
            "luochen1990/niri-ribbon:ribbon" = {
              animation_speed = 0.0;
              gaps = 10.0;
              viewport_model = "fit";
            };

            bluetooth.enabled = false;
            clipboard.enabled = false;
            media.enabled = false;
            session.enabled = false;
            volume.enabled = false;
          };
        };
      };
    };
  };
}
