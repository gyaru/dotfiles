_: {
  flake.modules.nixos.amd-server-power = {lib, ...}: let
    inherit (lib.lists) singleton;
  in {
    boot.kernelParams = singleton "amd_pstate=active";

    powerManagement = {
      enable = true;
      cpuFreqGovernor = "powersave";
    };

    systemd.services.cpufreq.postStart =
      /*
      bash
      */
      ''
        for policy in /sys/devices/system/cpu/cpufreq/policy*; do
          printf '%s\n' balance_performance > "$policy/energy_performance_preference"
        done
      '';
  };
}
