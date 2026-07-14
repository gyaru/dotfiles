_: {
  boot = {
    supportedFilesystems = ["zfs"];
    zfs = {
      forceImportRoot = false;
      extraPools = ["mlem"];
    };

    extraModprobeConfig = ''
      options zfs zfs_arc_max=17179869184
    '';
  };

  networking.hostId = "a8c06e77";

  modules.zfs = {
    snapshotPolicies."mlem/media" = {
      frequent = false;
      hourly = false;
    };
    scrubPools = ["mlem"];
  };

  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "Mon *-*-01..07 04:00:00";
      pools = ["mlem"];
      randomizedDelaySec = "0";
    };
    autoSnapshot = {
      enable = true;
      frequent = 4;
      hourly = 24;
      daily = 7;
      weekly = 4;
      monthly = 12;
    };
    trim.enable = true;
  };
}
