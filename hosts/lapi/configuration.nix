{
  config,
  flake,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkDefault;
  inherit (lib.lists) singleton;
in {
  imports = [
    inputs.agenix.nixosModules.default
    flake.modules.nixos.nix-builder
    flake.modules.nixos.kernel-hardening
    flake.modules.nixos.server-hardening
    flake.modules.nixos.amd-server-power
    flake.modules.nixos.ssh
    flake.modules.nixos.tailscale
    flake.modules.nixos.adguardhome
    flake.modules.nixos.firewall
    flake.modules.nixos.english-locale
    flake.modules.nixos.nix-index
    flake.modules.nixos.ntopng
    flake.modules.nixos.shell
    flake.modules.nixos.slop
    flake.modules.nixos.stockholm-time
    flake.modules.nixos.zfs
    ./services/k3s.nix
    ./services/bunny-plus.nix
    ./services/nvidia.nix
    ./services/grafana/default.nix
    ./zfs.nix
    ./services/samba.nix
    # ./services/wifi-ap.nix
    # ./services/router.nix
    ./services/network.nix
    flake.modules.nixos.virtual-machines
    # ./gaming.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [
        "amdgpu"
        "drivetemp"
      ];
    };
    kernelModules = [
      "kvm-amd"
      "nct6775"
      "ntsync"
    ];
    extraModulePackages = [];

    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };

    kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "ahci.mobile_lpm_policy=3"
      "split_lock_detect=off"
    ];

    blacklistedKernelModules = singleton "nouveau";
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/6fc670fd-404d-40b0-ae11-9f2352a23271";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C629-83F6";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [];

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
  };

  services = {
    openssh = {
      openFirewall = false;
      settings = {
        KbdInteractiveAuthentication = false;
      };
    };
    journald.settings.Journal = {
      SystemMaxUse = "2G";
      RuntimeMaxUse = "256M";
    };
    avahi.enable = false;
    fstrim.enable = true;

    ntopng = {
      interfaces = [
        "enp5s0"
        config.services.tailscale.interfaceName
        "cni0"
        "virbr0"
      ];
      extraConfig = "--local-networks=192.168.1.0/24,192.168.122.0/24,10.42.0.0/16,10.43.0.0/16,100.64.0.0/10,fd7a:115c:a1e0::/48";
    };
  };

  nixpkgs = {
    hostPlatform = mkDefault "x86_64-linux";
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  programs = {
    nix-ld.enable = true;
    git.enable = true;
  };

  networking = {
    hostName = "lapi";
    useDHCP = false;
    defaultGateway = "192.168.1.1";
    interfaces.enp5s0.ipv4.addresses = singleton {
      address = "192.168.1.240";
      prefixLength = 24;
    };
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "8.8.8.8"
    ];
  };

  age.secrets.k3s-token = {
    file = ../../secrets/k3s-token.age;
    mode = "0400";
    owner = "root";
    group = "root";
  };

  security.sudo.extraRules = singleton {
    users = singleton "lis";
    commands = singleton {
      command = "ALL";
      options = singleton "NOPASSWD";
    };
  };

  users = {
    mutableUsers = true;
    users = {
      root.openssh.authorizedKeys.keys = flake.adminSshKeys;
      lis = {
        isNormalUser = true;
        shell = pkgs.zsh;
        group = "users";
        extraGroups = [
          "wheel"
          "kvm"
          "usbpassthrough"
          "libvirtd"
        ];
        openssh.authorizedKeys.keys = flake.people.lis.sshKeys;
      };
      mikan = {
        isNormalUser = true;
        shell = pkgs.zsh;
        group = "users";
        extraGroups = [
          "wheel"
          "kvm"
          "usbpassthrough"
        ];
        openssh.authorizedKeys.keys = flake.people.mikan.sshKeys;
      };
    };
  };

  systemd = {
    oomd.enableUserSlices = true;

    services.ntopng.after = ["k3s.service" "libvirtd.service"];

    tmpfiles.rules = [
      "z /root/.ssh/authorized_keys 0600 root root -"
      "z /home/lis/.ssh/authorized_keys 0600 lis users -"
      "z /home/mikan/.ssh/authorized_keys 0600 mikan users -"
    ];

    targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };

  environment.systemPackages = with pkgs; [
    pciutils
    lm_sensors
    fanctl
    ntfs3g
    kubernetes-helm
    smartmontools
    ripgrep
    jq
    atool
    unrar
    tmux
  ];

  modules.slop.server = {
    enable = true;
    host = "100.88.168.16";
    openFirewall = true;
    interfaces = singleton config.services.tailscale.interfaceName;
  };

  system.stateVersion = "25.11";
}
