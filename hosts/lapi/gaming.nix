{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.meta) getExe;

  battleNet = pkgs.writeShellApplication {
    name = "battle-net";
    text =
      /*
      bash
      */
      ''
        export GAMEID="umu-battlenet"
        export PROTONPATH="/home/mikan/.steam/steam/compatibilitytools.d/GE-Proton11-1"
        export WINEPREFIX="/home/mikan/games/battle.net"
        export WINE_SIMULATE_WRITECOPY=1
        export PROTON_ENABLE_WAYLAND=0

        launcher="$WINEPREFIX/drive_c/Program Files (x86)/Battle.net/Battle.net Launcher.exe"

        [[ -x "$PROTONPATH/proton" ]] || { printf 'Missing Proton runner: %s\n' "$PROTONPATH" >&2; exit 1; }
        [[ -f "$launcher" ]] || { printf 'Missing Battle.net launcher: %s\n' "$launcher" >&2; exit 1; }

        exec ${getExe pkgs.umu-launcher} "$launcher"
      '';
  };

  battleNetDesktop = pkgs.makeDesktopItem {
    name = "battle-net";
    desktopName = "Battle.net";
    exec = "battle-net";
    icon = "applications-games";
    categories = ["Game"];
  };
in {
  environment = {
    sessionVariables.KWIN_DRM_DEVICES = "/dev/dri/nvidia-card";

    systemPackages = with pkgs; [
      steam
      gamescope
      mangohud
      protonup-qt
      curseforge
      umu-launcher
      vesktop
      telegram-desktop
      firefox
      battleNet
      battleNetDesktop
    ];
  };

  hardware = {
    graphics.enable = true;

    nvidia = {
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    };
  };

  services = {
    flatpak.enable = true;

    udev.extraRules = ''
      SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:01:00.0", DRIVERS=="nvidia", SYMLINK+="dri/nvidia-card"
    '';

    xserver.videoDrivers = ["nvidia"];

    displayManager.plasma-login-manager.enable = true;

    desktopManager = {
      plasma6.enable = true;
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  security.rtkit.enable = true;
}
