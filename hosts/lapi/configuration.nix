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
    inputs.nix-index-database.nixosModules.default
    flake.nixosModules.zfs
    ./services/k3s.nix
    ./services/grafana/default.nix
    ./zfs.nix
    ./services/samba.nix
    ./vm.nix
    ./gaming.nix
    ./kodi.nix
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
      "amd_pstate=active"
      "ahci.mobile_lpm_policy=1"
      "split_lock_detect=off"
    ];

    kernel.sysctl."vm.min_free_kbytes" = 524288;
    blacklistedKernelModules = ["nouveau"];
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
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

  time.timeZone = "Europe/Stockholm";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings.LC_TIME = "en_GB.UTF-8";
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
    avahi.allowInterfaces = ["eno1"];
    journald.extraConfig = ''
      SystemMaxUse=2G
      RuntimeMaxUse=256M
    '';

    tailscale.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };
    fstrim.enable = true;
  };

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
        "cgroups"
      ];
      use-cgroups = true;
      auto-optimise-store = true;
      max-jobs = "auto";
      cores = 0;
      eval-cache = true;
      substituters = [
        "https://cache.nixos.org?priority=10"
        "https://nix-community.cachix.org"
      ];
      system-features = [
        "big-parallel"
        "kvm"
        "nixos-test"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
  };

  programs = {
    zsh.enable = true;
    coolercontrol.enable = true;
  };

  networking = {
    hostName = "lapi";
    useDHCP = false;
    interfaces.eno1.ipv4.addresses = [
      {
        address = "192.168.1.240";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.1.1";
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "8.8.8.8"
    ];
    firewall = {
      enable = true;
      allowPing = false;
      logReversePathDrops = true;
      trustedInterfaces = ["tailscale0"];
    };
  };

  age.secrets.k3s-token = {
    file = ../../secrets/k3s-token.age;
    mode = "0400";
    owner = "root";
    group = "root";
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

  powerManagement.enable = true;

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  environment.systemPackages = with pkgs; [
    pciutils
    lm_sensors
    fanctl
    ntfs3g
    smartmontools
    comma
    ripgrep
    jq
    atool
    unrar
  ];

  systemd.services.disable-bad-usb4-port5 = {
    description = "Disable noisy usb4-port5";
    wantedBy = ["multi-user.target"];
    after = ["systemd-udev-settle.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      PORT="/sys/devices/pci0000:00/0000:00:02.1/0000:03:00.0/0000:04:08.0/0000:07:00.0/0000:08:0c.0/0000:0d:00.0/usb4/4-0:1.0/usb4-port5/disable"
      if [ -e "$PORT" ]; then
        echo 1 > "$PORT"
      fi
    '';
  };

  system.stateVersion = "25.11";
}
