_: {
  flake.modules.nixos.desktop = {pkgs, ...}: {
    environment.systemPackages = with pkgs.kdePackages; [ark dolphin];

    boot.kernel.sysctl = {
      "fs.file-max" = 2097152;

      "kernel.sched_autogroup_enabled" = 1;

      "vm.dirty_background_ratio" = 2;
      "vm.dirty_ratio" = 60;
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 75;
    };

    boot.tmp.useTmpfs = true;

    services.earlyoom.enable = true;

    hardware.bluetooth.enable = true;
  };
}
