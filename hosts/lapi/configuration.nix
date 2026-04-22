{
  config,
  outputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./k3s.nix
    ./zfs.nix
    ./samba.nix
    ./kodi.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"];
      kernelModules = ["vfio_pci" "vfio" "vfio_iommu_type1" "amdgpu" "drivetemp"];
    };
    kernelModules = ["kvm-amd" "nct6775" "ntsync"];
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
      "split_lock_detect=off"
    ];

    kernel.sysctl."vm.min_free_kbytes" = 524288;
    blacklistedKernelModules = ["nouveau"];
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/6fc670fd-404d-40b0-ae11-9f2352a23271";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C629-83F6";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [];

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        libvdpau-va-gl
        nvidia-vaapi-driver
      ];
    };

    steam-hardware.enable = true;

    nvidia = {
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement = {
        enable = true;
        finegrained = false;
      };
    };

    nvidia-container-toolkit.enable = true;
  };

  time.timeZone = "Europe/Stockholm";

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    journald.extraConfig = ''
      SystemMaxUse=2G
      RuntimeMaxUse=256M
    '';

    udev.extraRules = ''
      ACTION=="add", KERNEL=="6-5", SUBSYSTEM=="usb", ATTR{authorized}="0"
    '';

    tailscale.enable = true;
    xserver.videoDrivers = ["nvidia"];

    displayManager = {
      sddm.enable = true;
      autoLogin = {
        enable = true;
        user = "mikan";
      };
    };
    desktopManager.plasma6.enable = true;

    flatpak.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

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
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      max-jobs = "auto";
      cores = 0;
      eval-cache = true;
      substituters = [
        "https://cache.nixos.org?priority=10"
        "https://nix-community.cachix.org"
      ];
      system-features = ["big-parallel" "kvm" "nixos-test"];
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

    gamemode = {
      enable = true;
      settings = {
        general = {
          renice = 10;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 1;
        };
        gamemode = {
          whitelist = "Wow.exe";
        };
      };
    };

    steam = {
      enable = true;
      gamescopeSession.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = false;
      localNetworkGameTransfers.openFirewall = true;
    };

    xwayland.enable = true;
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

  users = let
    keys = import ../../keys.nix;
  in {
    mutableUsers = true;
    users = {
      root.openssh.authorizedKeys.keys = keys.adminSshKeys;
      lis = {
        isNormalUser = true;
        shell = pkgs.zsh;
        group = "users";
        extraGroups = ["wheel" "kvm" "usbpassthrough"];
        openssh.authorizedKeys.keys = keys.lisKeys;
      };
      mikan = {
        isNormalUser = true;
        shell = pkgs.zsh;
        group = "users";
        extraGroups = ["video" "audio" "input" "kvm" "usbpassthrough"];
        openssh.authorizedKeys.keys = keys.mikanKeys;
        packages = with pkgs; [
          mpv
          ffmpeg
          firefox-bin
          chromium
          telegram-desktop
          vesktop
          curseforge
          xrandr
          protonplus
        ];
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

  xdg.portal = {
    enable = true;

    config = {
      kde = {
        default = ["kde" "gtk" "gnome"];
        "org.freedesktop.portal.FileChooser" = ["kde"];
        "org.freedesktop.portal.OpenURI" = ["kde"];
      };
    };

    extraPortals = with pkgs.kdePackages; [
      xdg-desktop-portal-kde
    ];
  };

  environment.systemPackages = with pkgs; [
    pciutils
    lm_sensors
    fanctl
    ntfs3g
    nvtopPackages.nvidia
    smartmontools
    comma
  ];

  system.stateVersion = "25.11";
}
