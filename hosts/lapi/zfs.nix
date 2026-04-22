{pkgs, ...}: {
  boot = {
    supportedFilesystems = ["zfs"];
    zfs = {
      forceImportRoot = false;
      package = pkgs.zfs_2_4;
      extraPools = ["mlem"];
    };

    extraModprobeConfig = ''
      options zfs zfs_arc_max=17179869184
    '';
  };

  networking.hostId = "a8c06e77";

  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot.enable = true;
    trim.enable = true;
  };
}
