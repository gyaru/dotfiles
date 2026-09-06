{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) enum;

  cfg = config.modules.wayland;
in {
  options.modules.wayland = {
    enable = mkEnableOption "Wayland support";

    compositor = mkOption {
      type = enum ["hyprland" "sway" "niri"];
      default = "hyprland";
      description = "Wayland compositor to enable.";
    };
  };

  config = {
    environment.sessionVariables = {
      NIXOS_OZONE_WL = mkIf cfg.enable "1";
      QT_QPA_PLATFORM = mkIf cfg.enable "wayland;xcb";
      SDL_VIDEODRIVER = mkIf cfg.enable "wayland";
      _JAVA_AWT_WM_NONREPARENTING = mkIf cfg.enable "1";
    };

    programs = {
      dconf.enable = mkIf cfg.enable true;
      hyprland.enable = mkIf (cfg.enable && cfg.compositor == "hyprland") true;
      sway.enable = mkIf (cfg.enable && cfg.compositor == "sway") true;
      niri.enable = mkIf (cfg.enable && cfg.compositor == "niri") true;
      niri.useNautilus = mkIf (cfg.enable && cfg.compositor == "niri") false;
    };
  };
}
