{inputs, ...}: {
  flake.modules.hjem.noctalia = {
    config,
    lib,
    ...
  }: let
    inherit (lib.modules) mkAfter;
    inherit (lib.meta) getExe;
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
      programs.noctalia.enable = true;
      programs.noctalia.settings = {
        shell.corner_radius_scale = 0;
        bar.main = {
          capsule = false;
          concave_edge_corners = false;
          margin_ends = 0;
          radius = 0;
          radius_bottom_left = 0;
          radius_bottom_right = 0;
          radius_top_left = 0;
          radius_top_right = 0;
          start = ["launcher" "wallpaper" "workspaces"];
          center = singleton "clock";
          end =
            [
              "media"
              "tray"
              "notifications"
              "clipboard"
              "bluetooth"
              "volume"
              "control-center"
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
        plugins = {
          enabled = [];
          auto_update = "none";
          source = [
            {
              name = "official";
              kind = "git";
              location = "https://github.com/noctalia-dev/official-plugins";
              enabled = true;
            }
          ];
        };
      };
      rum.desktops.niri.spawn-at-startup = mkAfter <| singleton <| singleton <| getExe config.programs.noctalia.package;
    };
  };
}
