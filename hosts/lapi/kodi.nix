{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe;

  kodiGbm = pkgs.kodi-gbm.withPackages (_: []);

  kodiConfigure = pkgs.writeShellApplication {
    name = "kodi-configure";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.xmlstarlet
    ];
    text =
      /*
      bash
      */
      ''
        settings="''${KODI_SETTINGS:-/var/lib/kodi-tv/.kodi/userdata/guisettings.xml}"
        advancedSettings="$(dirname "$settings")/advancedsettings.xml"
        password="$(< "$1")"

        install --directory "$(dirname "$settings")"
        if [[ ! -s "$settings" ]]; then
          printf '<settings version="2"></settings>\n' > "$settings"
        fi

        set_setting() {
          local id="$1"
          local value="$2"

          if [[ "$(xmlstarlet select --template --value-of "count(/settings/setting[@id='$id'])" "$settings")" != 0 ]]; then
            xmlstarlet edit --inplace --update "/settings/setting[@id='$id']" --value "$value" "$settings"
          else
            xmlstarlet edit --inplace --subnode /settings --type elem --name setting --value "$value" "$settings"
            xmlstarlet edit --inplace --insert "/settings/setting[last()]" --type attr --name id --value "$id" "$settings"
          fi

          xmlstarlet edit --inplace --delete "/settings/setting[@id='$id']/@default" "$settings"
        }

        set_setting services.devicename "Kodi TV"
        set_setting services.zeroconf true
        set_setting services.webserver true
        set_setting services.webserverport 8080
        set_setting services.webserverauthentication true
        set_setting services.webserverusername kodi
        set_setting services.webserverpassword "$password"
        set_setting services.esenabled true
        set_setting services.esallinterfaces true

        if [[ ! -s "$advancedSettings" ]]; then
          printf '<advancedsettings version="1.0"></advancedsettings>\n' > "$advancedSettings"
        fi

        xmlstarlet edit --inplace \
          --delete /advancedsettings/cache \
          "$advancedSettings"
        xmlstarlet edit --inplace \
          --subnode /advancedsettings --type elem --name cache \
          --subnode /advancedsettings/cache --type elem --name buffermode --value 1 \
          --subnode /advancedsettings/cache --type elem --name memorysize --value 536870912 \
          --subnode /advancedsettings/cache --type elem --name readfactor --value 8 \
          "$advancedSettings"
      '';
  };

  kodiTv = pkgs.writeShellApplication {
    name = "kodi-tv";
    text =
      /*
      bash
      */
      ''
        export __EGL_VENDOR_LIBRARY_FILENAMES=${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json
        export LIBSEAT_BACKEND=seatd
        export DRI_PRIME=pci-0000_11_00_0!
        export LIBVA_DRIVER_NAME=radeonsi

        exec ${getExe kodiGbm} --standalone --windowing=gbm
      '';
  };
in {
  age.secrets.kodi-password = {
    file = ../../secrets/kodi-password.age;
    mode = "0400";
    owner = "kodi-tv";
    group = "kodi-tv";
  };

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

    preStart = "${getExe kodiConfigure} ${config.age.secrets.kodi-password.path}";

    serviceConfig = {
      ExecStart = getExe kodiTv;
      InaccessiblePaths = [
        "/dev/dri/card2"
        "/dev/dri/renderD129"
        "/dev/nvidia0"
        "/dev/nvidiactl"
        "/dev/nvidia-modeset"
        "/dev/nvidia-uvm"
        "/dev/nvidia-uvm-tools"
      ];
      Restart = "on-failure";
      RestartSec = "2s";
      RuntimeDirectory = "kodi-tv";
      RuntimeDirectoryMode = "0700";
      StateDirectory = "kodi-tv";
      TimeoutStopSec = "15s";
      User = "kodi-tv";
      Group = "kodi-tv";
    };
  };
}
