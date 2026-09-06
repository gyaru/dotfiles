_: {
  flake.modules.nixos.kernel-hardening = {
    boot.kernel.sysctl = {
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
      "fs.suid_dumpable" = 0;

      "kernel.kptr_restrict" = 2;
      "kernel.ftrace_enabled" = 0;
      "kernel.perf_event_paranoid" = 3;
    };
  };
}
