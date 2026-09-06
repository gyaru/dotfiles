{
  inputs,
  flake,
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.lists) singleton;
  inherit (lib.modules) mkDefault mkForce;
  windowsBootEntry =
    pkgs.writeText "windows.conf"
    /*
    ini
    */
    ''
      title Windows 11
      efi /efi/edk2-uefi-shell/shell.efi
      options -nointerrupt -nomap -noversion HD0b:EFI\Microsoft\Boot\Bootmgfw.efi
      sort-key 00-windows
    '';
in {
  imports = [
    inputs.hjem.nixosModules.default
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.nix-index-database.nixosModules.nix-index
    flake.nixosModules.amd
    flake.nixosModules.audio
    flake.nixosModules.base
    flake.nixosModules.desktop
    flake.nixosModules.gaming
    flake.nixosModules.security
    flake.nixosModules.wayland
    ./users/lis.nix
  ];

  modules.wayland = {
    enable = true;
    compositor = "niri";
  };

  modules.audio = {
    enable = true;
    defaultSink = "alsa_output.usb-Schiit_Audio_Schiit_Magni_Unity-00.analog-stereo";
    defaultSource = "alsa_input.usb-Elgato_Systems_Elgato_Wave_3_BS41M1A00911-00.mono-fallback";
    sampleRate = 48000;
    quantumSize = 1024;
    extraConfig = {
      "resample.quality" = 10;
      "pulse.min.quantum" = 1024;
    };
  };

  nixpkgs = {
    hostPlatform = mkDefault "x86_64-linux";
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
      system-features = [
        "big-parallel"
        "kvm"
        "nixos-test"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  networking = {
    hostName = "radiata";
    networkmanager.enable = true;
    useDHCP = mkDefault true;
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "8.8.8.8"
      "8.8.4.4"
    ];
    firewall = {
      enable = true;
      allowPing = false;
      checkReversePath = "loose";
      logReversePathDrops = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/1828ab6b-52a6-4723-86b8-54629eb390e1";
      fsType = "btrfs";
    };
    "/efi" = {
      device = "/dev/disk/by-uuid/020A-56A8";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
      neededForBoot = true;
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/027C-6880";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
      neededForBoot = true;
    };
    "/mnt/koharu" = {
      device = "/dev/disk/by-uuid/CC76855576854166";
      fsType = "ntfs-3g";
      options = ["nofail" "uid=1000" "gid=100" "umask=0022"];
    };
  };

  swapDevices = [];

  boot = {
    # consoleLogLevel = 0;
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
    kernelParams = [
      "mitigations=off"
      "preempt=full"
      "quiet"
      "udev.log_level=3"
    ];

    kernelModules = singleton "kvm-amd";
    extraModulePackages = [];

    initrd = {
      availableKernelModules = [
        "nvme"
        "ahci"
        "xhci_pci"
        "thunderbolt"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [];
      systemd.enable = true;
      supportedFilesystems = singleton "btrfs";
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    loader = {
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/efi";
      systemd-boot = {
        enable = mkForce false;
        configurationLimit = 5;
        consoleMode = "max";
        editor = false;
        xbootldrMountPoint = "/boot";
      };
    };
  };

  # a signed EDK2 shell and its windows chainloader entry into boot
  systemd.services.lanzaboote-windows-entry = {
    description = "Install the Windows Lanzaboote entry";
    wantedBy = singleton "multi-user.target";
    after = ["efi.mount" "boot.mount"];
    requires = ["efi.mount" "boot.mount"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script =
      /*
      bash
      */
      ''
        ${pkgs.coreutils}/bin/install -d -m 0755 /boot/efi/edk2-uefi-shell
        shell_tmp=$(${pkgs.coreutils}/bin/mktemp /boot/efi/edk2-uefi-shell/shell.efi.XXXXXX)
        trap '${pkgs.coreutils}/bin/rm -f "$shell_tmp"' EXIT
        ${pkgs.sbsigntool}/bin/sbsign \
          --key '${config.boot.lanzaboote.privateKeyFile}' \
          --cert '${config.boot.lanzaboote.publicKeyFile}' \
          --output "$shell_tmp" \
          '${pkgs.edk2-uefi-shell}/shell.efi'
        ${pkgs.coreutils}/bin/install -m 0644 "$shell_tmp" /boot/efi/edk2-uefi-shell/shell.efi
        ${pkgs.coreutils}/bin/install -Dm 0644 '${windowsBootEntry}' /boot/loader/entries/windows.conf
      '';
  };

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
  };

  environment = {
    binsh = "${pkgs.zsh}/bin/zsh";
    pathsToLink = singleton "/share/zsh";
    shells = with pkgs; [zsh];
    systemPackages = with pkgs; [
      git
      ntfs3g
      sbctl
    ];
  };

  fonts = {
    packages = with pkgs; [
      balsamiqsans
      lucide-icons
      maple-mono.NF
      mplus-fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      noto-fonts-monochrome-emoji
    ];
    fontconfig = {
      enable = mkDefault true;
      defaultFonts = {
        monospace = singleton "M PLUS 1 Code";
        emoji = singleton "Noto Color Emoji";
      };
      antialias = true;
      hinting = {
        enable = true;
        style = "full";
      };
      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };
    };
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "en_DK.UTF-8/UTF-8"
      "en_GB.UTF-8/UTF-8"
    ];
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_COLLATE = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_DK.UTF-8";
      LC_MEASUREMENT = "en_DK.UTF-8";
      LC_MESSAGES = "en_US.UTF-8";
      LC_MONETARY = "en_DK.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_DK.UTF-8";
      LC_TELEPHONE = "en_DK.UTF-8";
      LC_TIME = "en_GB.UTF-8";
    };
  };

  users.users.lis = {
    isNormalUser = true;
    shell = pkgs.zsh;
    group = "users";
    extraGroups = singleton "wheel";
  };

  programs = {
    command-not-found.enable = false;
    zsh.enable = true;
    nix-index-database.comma.enable = true;
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  xdg.portal = {
    enable = true;
    config.common.default = singleton "gnome";
    extraPortals = [];
  };

  security = {
    sudo.wheelNeedsPassword = false;
  };

  time = {
    timeZone = "Europe/Stockholm";
    hardwareClockInLocalTime = true;
  };

  system.stateVersion = "26.05";
}
