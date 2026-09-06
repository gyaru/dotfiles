{
  config,
  lib,
  ...
}: let
  inherit (lib.lists) singleton;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) bool listOf str;
  cfg = config.modules.impermanence;
in {
  options.modules.impermanence = {
    enable = mkOption {
      type = bool;
      default = false;
      description = "Enable impermanence with BTRFS rollback";
    };

    btrfsRootUuid = mkOption {
      type = str;
      description = "UUID of the BTRFS root partition";
      example = "caf259ee-b2be-4cf8-b41a-752a09d344a7";
    };

    persistentDirectories = mkOption {
      type = listOf str;
      default = [];
      description = "Additional directories to persist";
    };
  };

  config = mkIf cfg.enable {
    boot.initrd = {
      systemd.services.rollback = {
        description = "rollback BTRFS root subvolume to a clean state";
        wantedBy = singleton "initrd.target";
        before = singleton "sysroot.mount";
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script =
          /*
          bash
          */
          ''
            mkdir -p /mnt
            mount -t btrfs -o subvol=/ /dev/disk/by-uuid/${cfg.btrfsRootUuid} /mnt
            btrfs subvolume list -o /mnt/root |
              cut -f9 -d' ' |
              while read subvolume; do
                echo "deleting /$subvolume subvolume..."
                btrfs subvolume delete "/mnt/$subvolume"
              done &&
              echo "deleting /root subvolume..." &&
              btrfs subvolume delete /mnt/root
            echo "restoring blank /root subvolume..."
            btrfs subvolume snapshot /mnt/root-blank /mnt/root
            umount /mnt
          '';
      };

      systemd.services.persisted-files = {
        description = "hard-link persisted files from /persist";
        wantedBy = singleton "initrd.target";
        after = singleton "sysroot.mount";
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script =
          /*
          bash
          */
          ''
            mkdir -p /sysroot/etc/
            ln -snfT /persist/etc/machine-id /sysroot/etc/machine-id
          '';
      };
    };

    environment.persistence."/persist" = {
      hideMounts = true;
      directories =
        [
          "/var/log"
          "/etc/secureboot"
          "/var/lib/bluetooth"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
        ]
        ++ cfg.persistentDirectories;
    };

    fileSystems."/persist".neededForBoot = true;
  };
}
