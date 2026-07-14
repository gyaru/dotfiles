{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.wayland;
in {
  options.modules.wayland = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Wayland support";
    };

    compositor = lib.mkOption {
      type = lib.types.enum [
        "hyprland"
        "sway"
      ];
      default = "hyprland";
      description = "Wayland compositor to use";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland";
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };

    programs.dconf.enable = true;

    xdg.portal = {
      enable = true;
      wlr.enable = cfg.compositor == "sway";
      extraPortals = with pkgs;
        if cfg.compositor == "hyprland"
        then [
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
        ]
        else if cfg.compositor == "sway"
        then [
          xdg-desktop-portal-wlr
          xdg-desktop-portal-gtk
        ]
        else [xdg-desktop-portal-gtk];

      config = {
        common = {
          default =
            if cfg.compositor == "hyprland"
            then ["hyprland"]
            else if cfg.compositor == "sway"
            then ["wlr"]
            else ["gtk"];
        };
      };
    };
  };
}
