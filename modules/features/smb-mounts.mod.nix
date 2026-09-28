{
  inputs,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists) singleton;
in {
  flake.modules.nixos.smb-mounts = {
    config,
    flake,
    ...
  }: {
    imports = singleton inputs.agenix.nixosModules.default;

    age.identityPaths = singleton "/var/lib/agenix/identity";

    age.secrets.lapi-smb = {
      file = ../../secrets/lapi-smb.age;
      mode = "0400";
    };

    fileSystems =
      mapAttrs (_: share: {
        device = "//${flake.machines.lapi.ssh.hostName}/${share}";
        fsType = "cifs";
        options = [
          "credentials=${config.age.secrets.lapi-smb.path}"
          "uid=${config.users.users.lis.name}"
          "gid=${config.users.users.lis.group}"
          "forceuid"
          "forcegid"
          "file_mode=0600"
          "dir_mode=0700"
          "vers=3.1.1"
          "nosuid"
          "nodev"
          "_netdev"
          "nofail"
          "x-systemd.automount"
          "x-systemd.idle-timeout=5min"
          "x-systemd.mount-timeout=15s"
          "x-systemd.requires=tailscaled.service"
        ];
      }) {
        "/mnt/media" = "media";
        "/mnt/personal" = "personal";
      };
  };
}
