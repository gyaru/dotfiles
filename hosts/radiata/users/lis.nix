{
  flake,
  inputs,
  config,
  lib,
  ...
}: let
  inherit (lib.meta) getExe';
  inherit (lib.modules) mkForce;
in {
  hjem = {
    clobberByDefault = true;
    extraModules = [
      inputs.hjem-rum.hjemModules.default
      flake.modules.hjem.workstation
      flake.modules.hjem."battle.net"
      flake.modules.hjem.hyprland
      flake.modules.hjem.yubikey
    ];

    users.lis = {
      enable = true;
      user = "lis";
      directory = "/home/lis";

      rum.desktops.niri.enable = mkForce false;

      rum.programs.zsh.loginConfig =
        mkForce
        /*
        zsh
        */
        ''
          if [[ -z "$WAYLAND_DISPLAY" && -z "$DISPLAY" && "$TTY" == /dev/tty1 ]]; then
            exec ${getExe' config.programs.hyprland.package "start-hyprland"}
          fi
        '';
    };
  };
}
