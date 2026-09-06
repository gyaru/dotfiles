{
  lib,
  modulesPath,
  ...
}: let
  inherit (lib.lists) singleton;
  inherit (lib.modules) mkDefault;
in {
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];

  boot = {
    initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "virtio_pci"
      "virtio_scsi"
      "sd_mod"
    ];
    initrd.kernelModules = [];
    kernelModules = singleton "kvm-intel";
    extraModulePackages = [];
  };

  nixpkgs.hostPlatform = mkDefault "x86_64-linux";
}
