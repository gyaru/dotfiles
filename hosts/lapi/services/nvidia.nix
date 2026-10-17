{config, ...}: {
  boot.kernelModules = ["nvidia" "nvidia_uvm"];

  hardware = {
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      open = false;
      nvidiaSettings = false;
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    };
  };

  services.xserver.videoDrivers = ["nvidia"];
}
