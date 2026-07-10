{pkgs, ...}: {
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      vhostUserPackages = with pkgs; [
        virtiofsd
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    qemu_kvm
    libvirt
    swtpm
    virtio-win
    virtiofsd
    pciutils
    usbutils
    OVMFFull
  ];

  users.users.lis.extraGroups = [
    "libvirtd"
    "kvm"
  ];

  networking.firewall.trustedInterfaces = [
    "virbr0"
  ];
}
