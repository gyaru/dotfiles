_: {
  flake.modules.nixos.server-hardening = {
    security.protectKernelImage = true;

    systemd.coredump = {
      enable = true;
      settings.Coredump = {
        Storage = "none";
        ProcessSizeMax = 0;
      };
    };
  };
}
