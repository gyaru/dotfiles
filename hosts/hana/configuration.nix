{
  config,
  flake,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    flake.nixosModules.base
  ];

  boot.initrd.availableKernelModules = [
    "uas"
    "usb_storage"
    "xhci_pci"
  ];

  environment.systemPackages = [
    pkgs.alsa-utils
    pkgs.git
    pkgs.htop
    pkgs.usbutils
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/de71366b-ea04-4daa-a6e5-23a719f8af0e";
    fsType = "ext4";
    options = ["noatime"];
  };

  hardware.enableRedistributableFirmware = true;

  networking.networkmanager.enable = true;

  nix = {
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "flakes"
        "nix-command"
        "pipe-operators"
      ];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  security.sudo.wheelNeedsPassword = false;

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  };

  time.timeZone = "Europe/Stockholm";

  users.users.lis = {
    isNormalUser = true;
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "render"
      "video"
      "wheel"
    ];
    openssh.authorizedKeys.keys = flake.people.lis.sshKeys;
  };

  system.stateVersion = "26.05";
}
