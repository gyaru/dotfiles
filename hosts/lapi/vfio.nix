{lib, ...}: {
  boot = {
    initrd.kernelModules = lib.mkBefore [
      "vfio"
      "vfio_pci"
      "vfio_iommu_type1"
    ];
    kernelParams = [
      "vfio-pci.ids=10de:1f02,10de:10f9,10de:1ada,10de:1adb"
    ];
    blacklistedKernelModules = [
      "nouveau"
      "nvidiafb"
      "nvidia"
      "nvidia_drm"
      "nvidia_modeset"
      "nvidia_uvm"
    ];
    extraModprobeConfig = ''
      options vfio-pci ids=10de:1f02,10de:10f9,10de:1ada,10de:1adb
    '';
  };
}
