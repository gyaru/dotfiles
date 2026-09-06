_: {
  flake.modules.nixos.virtual-machines = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.lists) singleton;
  in {
    environment.systemPackages = with pkgs; [
      config.virtualisation.libvirtd.qemu.package
      libvirt
      config.virtualisation.libvirtd.qemu.swtpm.package
      virtio-win
      virtiofsd
      pciutils
      usbutils
      OVMFFull
    ];

    virtualisation.libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        vhostUserPackages = singleton pkgs.virtiofsd;
      };
    };

    networking.firewall.trustedInterfaces = singleton "virbr0";
  };
}
