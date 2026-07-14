{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.zfs;
  inherit (lib.attrsets) mapAttrs' nameValuePair optionalAttrs;
  inherit (lib.lists) head;
  inherit (lib.meta) getExe';
  inherit (lib.options) mkOption;
  inherit (lib.strings) concatMapStringsSep escapeShellArg escapeShellArgs replaceStrings splitString;
  inherit (lib.trivial) boolToString;
  inherit (lib.types) attrsOf bool listOf str submodule;

  zfs = getExe' config.boot.zfs.package "zfs";
  zpool = getExe' config.boot.zfs.package "zpool";
  systemdCat = getExe' pkgs.systemd "systemd-cat";
  wall = getExe' pkgs.util-linux "wall";

  snapshotFrequencies = [
    "frequent"
    "hourly"
    "daily"
    "weekly"
    "monthly"
  ];

  mkSnapshotPolicyService = dataset: policy: let
    pool = head (splitString "/" dataset);
    serviceName = "zfs-snapshot-policy-${replaceStrings ["/"] ["-"] dataset}";
  in
    nameValuePair serviceName {
      description = "Configure ZFS snapshot policy for ${dataset}";
      wantedBy = ["multi-user.target"];
      after = ["zfs-import-${pool}.service"];
      requires = ["zfs-import-${pool}.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script =
        concatMapStringsSep "\n" (
          frequency: "${zfs} set com.sun:auto-snapshot:${frequency}=${boolToString policy.${frequency}} ${escapeShellArg dataset}"
        )
        snapshotFrequencies;
    };

  scrubPools = escapeShellArgs cfg.scrubPools;
  checkScrub =
    pkgs.writeShellScript "check-zfs-scrub"
    /*
    bash
    */
    ''
      ${zpool} status -x ${scrubPools}
    '';
in {
  options.modules.zfs = {
    snapshotPolicies = mkOption {
      type = attrsOf (submodule {
        options = {
          frequent = mkOption {
            type = bool;
            default = true;
          };
          hourly = mkOption {
            type = bool;
            default = true;
          };
          daily = mkOption {
            type = bool;
            default = true;
          };
          weekly = mkOption {
            type = bool;
            default = true;
          };
          monthly = mkOption {
            type = bool;
            default = true;
          };
        };
      });
      default = {};
      description = "Per-dataset zfs-auto-snapshot policies.";
    };

    scrubPools = mkOption {
      type = listOf str;
      default = [];
      description = "Pools whose health is checked after automatic scrubs.";
    };
  };

  config.systemd.services =
    mapAttrs' mkSnapshotPolicyService cfg.snapshotPolicies
    // optionalAttrs (cfg.scrubPools != []) {
      zfs-scrub = {
        onFailure = ["zfs-scrub-failure.service"];
        serviceConfig.ExecStartPost = checkScrub;
      };

      zfs-scrub-failure = {
        description = "Report failed ZFS scrub";
        serviceConfig.Type = "oneshot";
        script =
          /*
          bash
          */
          ''
            status="$(${zpool} status -xv ${scrubPools} 2>&1 || true)"
            printf '%s\n' "$status" | ${systemdCat} --identifier=zfs-scrub --priority=err
            printf 'ZFS scrub failed on %s\n%s\n' ${escapeShellArg config.networking.hostName} "$status" | ${wall}
          '';
      };
    };
}
