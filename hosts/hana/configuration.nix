{
  config,
  flake,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.agenix.nixosModules.default
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    flake.nixosModules.base
  ];

  age.secrets.hana-wifi-password = {
    file = ../../secrets/hana-wifi-password.age;
    mode = "0400";
    owner = "root";
    group = "root";
  };

  boot.initrd.availableKernelModules = [
    "uas"
    "usb_storage"
    "xhci_pci"
  ];
  boot.loader = {
    efi = {
      canTouchEfiVariables = false;
      efiSysMountPoint = "/boot";
    };
    generic-extlinux-compatible.enable = lib.mkForce false;
    grub = {
      enable = true;
      device = "nodev";
      efiInstallAsRemovable = true;
      efiSupport = true;
    };
  };

  environment.systemPackages = [
    pkgs.alsa-utils
    pkgs.git
    pkgs.htop
    pkgs.usbutils
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/HANA_ROOT";
    fsType = "ext4";
    options = ["noatime"];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/HANA_FW";
    fsType = "vfat";
    options = [
      "dmask=0022"
      "fmask=0022"
    ];
  };

  hardware = {
    enableRedistributableFirmware = true;
    graphics.enable = true;
    raspberry-pi.firmware = {
      enable = true;
      path = "/boot";
      uboot.enable = true;
    };
  };

  networking.networkmanager = {
    enable = true;
    ensureProfiles = {
      profiles.mimi = {
        connection = {
          autoconnect = true;
          id = "mimi";
          interface-name = "wlan0";
          type = "wifi";
          uuid = "76099f93-6f07-423d-9a91-4c118cc1d11a";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "mimi";
        };
        wifi-security = {
          auth-alg = "open";
          key-mgmt = "wpa-psk";
          psk-flags = 1;
        };
        ipv4.method = "auto";
        ipv6 = {
          addr-gen-mode = "stable-privacy";
          method = "auto";
        };
      };
      secrets.entries = lib.lists.singleton {
        matchId = "mimi";
        matchSetting = "802-11-wireless-security";
        key = "psk";
        file = config.age.secrets.hana-wifi-password.path;
      };
    };
  };

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
    cage = {
      enable = true;
      environment.WLR_LIBINPUT_NO_DEVICES = "1";
      program =
        pkgs.writeShellScript "glmark2-wayland-demo"
        /*
        bash
        */
        ''
          ${pkgs.wlr-randr}/bin/wlr-randr --output HDMI-A-2 --mode 1920x1080@60Hz
          exec ${pkgs.glmark2}/bin/glmark2-wayland --fullscreen --run-forever
        '';
      user = "lis";
    };

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
