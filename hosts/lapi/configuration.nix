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
    flake.modules.nixos.ssh
    flake.modules.nixos.tailscale
    flake.modules.nixos.adguardhome
    flake.modules.nixos.firewall
    flake.modules.nixos.english-locale
    flake.modules.nixos.nix-index
    flake.modules.nixos.shell
    flake.modules.nixos.stockholm-time
    flake.modules.nixos.zfs
    ./services/k3s.nix
    ./services/bunny-plus.nix
    ./services/grafana/default.nix
    ./zfs.nix
    ./services/samba.nix
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
      "amd_pstate=active"
      "ahci.mobile_lpm_policy=1"
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
    avahi.allowInterfaces = singleton "eno1";
    journald.extraConfig =
      /*
      ini
      */
      ''
        SystemMaxUse=2G
        RuntimeMaxUse=256M
      '';

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
    hostPlatform = mkDefault "x86_64-linux";
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  programs = {
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

  powerManagement.enable = true;

  systemd = {
    oomd.enableUserSlices = true;

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

    services.disable-bad-usb4-port5 = {
      description = "Disable noisy usb4-port5";
      wantedBy = singleton "multi-user.target";
      after = singleton "systemd-udev-settle.service";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script =
        /*
        bash
        */
        ''
          PORT="/sys/devices/pci0000:00/0000:00:02.1/0000:03:00.0/0000:04:08.0/0000:07:00.0/0000:08:0c.0/0000:0d:00.0/usb4/4-0:1.0/usb4-port5/disable"
          if [ -e "$PORT" ]; then
            echo 1 > "$PORT"
          fi
        '';
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

  system.stateVersion = "25.11";
}
