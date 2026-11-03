{self, ...}: {
  flake.modules.nixos.kodi-tv = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.lists) singleton;
    inherit (lib.meta) getExe;
    inherit (lib.options) mkOption;
    inherit (lib.strings) escapeShellArg;
    inherit (lib.types) package port str;

    cfg = config.services.kodi-tv;
  in {
    options.services.kodi-tv = {
      package = mkOption {
        type = package;
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.kodi-tv.withPackages (addons: singleton addons.jellyfin);
        description = "Kodi GBM package with AMD primary-plane support and display recovery.";
      };

      device = mkOption {
        type = str;
        description = "DRM card used exclusively by Kodi.";
      };

      renderDevice = mkOption {
        type = str;
        description = "Render node belonging to Kodi's DRM card.";
      };

      connector = mkOption {
        type = str;
        description = "TV connector on Kodi's DRM card.";
      };

      audioDevice = mkOption {
        type = str;
        description = "Kodi ALSA device for the TV's HDMI audio.";
      };

      audioCard = mkOption {
        type = str;
        description = "WirePlumber card name reserved for Kodi's HDMI audio.";
      };

      passwordFile = mkOption {
        type = str;
        description = "Runtime file containing the Kodi remote password.";
      };

      httpPort = mkOption {
        type = port;
        default = 8080;
        description = "HTTP port for authenticated Kodi phone remotes.";
      };
    };

    config = {
      users.groups.kodi-tv = {};

      users.users.kodi-tv = {
        isSystemUser = true;
        group = "kodi-tv";
        extraGroups = ["video" "render" "audio"];
        home = "/var/lib/kodi-tv";
      };

      hardware.graphics.enable = true;

      services.pipewire.wireplumber.extraConfig."51-kodi-tv"."monitor.alsa.rules" = singleton {
        matches = singleton {"device.name" = cfg.audioCard;};
        actions.update-props."device.disabled" = true;
      };

      systemd.services.kodi-tv = {
        description = "Kodi on the TV";
        wantedBy = singleton "graphical.target";
        after = ["systemd-udev-trigger.service" "sound.target" "network.target"];

        environment = {
          HOME = config.users.users.kodi-tv.home;
          XDG_RUNTIME_DIR = "/run/kodi-tv";
          LIBVA_DRIVER_NAME = "radeonsi";
          GBM_BACKEND = "dri";
        };

        preStart =
          /*
          bash
          */
          ''
            test -c ${escapeShellArg cfg.device}
            test -c ${escapeShellArg cfg.renderDevice}

            ${getExe pkgs.python3} ${./kodi-tv-configure.py} \
              --settings ${escapeShellArg "${config.users.users.kodi-tv.home}/.kodi/userdata/guisettings.xml"} \
              --connector ${escapeShellArg cfg.connector} \
              --audio-device ${escapeShellArg cfg.audioDevice} \
              --http-port ${toString cfg.httpPort} \
              --password-file "$CREDENTIALS_DIRECTORY/remote-password"
          '';

        serviceConfig = {
          User = config.users.users.kodi-tv.name;
          Group = config.users.users.kodi-tv.group;
          StateDirectory = "kodi-tv";
          StateDirectoryMode = "0700";
          RuntimeDirectory = "kodi-tv";
          RuntimeDirectoryMode = "0700";
          WorkingDirectory = config.users.users.kodi-tv.home;
          LoadCredential = singleton "remote-password:${cfg.passwordFile}";
          ExecStart = "${getExe cfg.package} --standalone --windowing=gbm --audio-backend=alsa --logging=console";
          Restart = "always";
          RestartSec = 10;
          UMask = "0077";
          DevicePolicy = "closed";
          DeviceAllow = [
            "${cfg.device} rw"
            "${cfg.renderDevice} rw"
            "char-alsa rw"
          ];
        };
      };
    };
  };
}
