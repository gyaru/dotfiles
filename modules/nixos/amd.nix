_: {
  boot = {
    kernelParams = [
      "amd_pstate.shared_mem=1"
      "amd_pstate=guided"
      "amdgpu.dc=1"
      "amdgpu.ppfeaturemask=0xffffffff"
      "initcall_blacklist=acpi_cpufreq_init"
      "radeon.cik_support=0"
      "radeon.si_support=0"
    ];

    kernelModules = ["kvm-amd"];

    initrd.kernelModules = [
      "amdgpu"
      "nct6775"
    ];
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  powerManagement.cpuFreqGovernor = "performance";
}
