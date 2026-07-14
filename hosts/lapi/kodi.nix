{
  lib,
  pkgs,
  ...
}: let
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe;

  kodiWayland = pkgs.kodi-wayland.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./kodi-giflib-6.patch];
  });

  kodiClient = pkgs.writeShellApplication {
    name = "kodi-client";
    text =
      /*
      bash
      */
      ''
        ${getExe pkgs.wlr-randr} --output HDMI-A-1 --mode 3840x2160@60Hz
        exec ${getExe kodiWayland} --standalone --windowing=x11
      '';
  };

  kodiTv = pkgs.writeShellApplication {
    name = "kodi-tv";
    text =
      /*
      bash
      */
      ''
        export WLR_BACKENDS=drm
        export WLR_DRM_DEVICES=/dev/dri/amd-tv-card
        export WLR_LIBINPUT_NO_DEVICES=1
        export LIBSEAT_BACKEND=seatd
        export DRI_PRIME=pci-0000_11_00_0
        export LIBVA_DRIVER_NAME=radeonsi

        exec ${getExe pkgs.cage} -- ${getExe kodiClient}
      '';
  };
in {
  environment.systemPackages = singleton kodiTv;

  users = {
    groups.kodi-tv = {};
    users.kodi-tv = {
      isSystemUser = true;
      group = "kodi-tv";
      home = "/var/lib/kodi-tv";
      extraGroups = [
        "audio"
        "render"
        "seat"
        "video"
      ];
    };
  };

  services = {
    seatd.enable = true;

    udev.extraRules = ''
      SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:11:00.0", DRIVERS=="amdgpu", SYMLINK+="dri/amd-tv-card"
    '';
  };

  systemd.services.kodi-tv = {
    description = "Kodi on the AMD-connected TV";
    wantedBy = ["graphical.target"];
    after = [
      "network-online.target"
      "seatd.service"
      "systemd-udev-settle.service"
    ];
    wants = ["network-online.target"];
    requires = ["seatd.service"];

    environment = {
      HOME = "/var/lib/kodi-tv";
      XDG_RUNTIME_DIR = "/run/kodi-tv";
    };

    serviceConfig = {
      ExecStart = getExe kodiTv;
      Restart = "on-failure";
      RestartSec = "2s";
      RuntimeDirectory = "kodi-tv";
      RuntimeDirectoryMode = "0700";
      StateDirectory = "kodi-tv";
      User = "kodi-tv";
      Group = "kodi-tv";
    };
  };
}
