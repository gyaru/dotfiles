{
  inputs,
  flake,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    (inputs.impermanence + "/nixos.nix")
    flake.nixosModules.amd
    flake.nixosModules.desktop
    flake.nixosModules.gaming
    flake.nixosModules.audio
    flake.nixosModules.wayland
    flake.nixosModules.base
    flake.nixosModules.impermanence
    flake.nixosModules.security
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.nix-index-database.nixosModules.nix-index
    inputs.hjem.nixosModules.default
    ./users/lis.nix
  ];

  modules = {
    wayland = {
      enable = true;
      compositor = "hyprland";
    };
    impermanence = {
      enable = true;
      btrfsRootUuid = "caf259ee-b2be-4cf8-b41a-752a09d344a7";
      persistentDirectories = [
        "/var/lib/flatpak"
        "/etc/coolercontrol"
      ];
    };
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
    hostPlatform = lib.mkDefault "x86_64-linux";
  };

  nix = {
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

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
        "https://anyrun.cachix.org"
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
        "https://nix-gaming.cachix.org"
      ];
      system-features = [
        "big-parallel"
        "kvm"
        "nixos-test"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
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
    useDHCP = lib.mkDefault true;
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "8.8.8.8"
      "8.8.4.4"
    ]; # cloudflare, google as backup
    firewall = {
      enable = true;
      allowPing = false;
      logReversePathDrops = true;
    };
  };

  fileSystems = {
    # root
    "/" = {
      device = "/dev/disk/by-uuid/caf259ee-b2be-4cf8-b41a-752a09d344a7";
      fsType = "btrfs";
      options = [
        "subvol=root"
        "compress=zstd:1"
        "noatime"
        "discard=async"
        "space_cache=v2"
      ];
    };
    # nix
    "/nix" = {
      device = "/dev/disk/by-uuid/caf259ee-b2be-4cf8-b41a-752a09d344a7";
      fsType = "btrfs";
      options = [
        "subvol=nix"
        "compress=zstd:1"
        "noatime"
        "discard=async"
        "space_cache=v2"
      ];
    };
    # persist
    "/persist" = {
      device = "/dev/disk/by-uuid/caf259ee-b2be-4cf8-b41a-752a09d344a7";
      fsType = "btrfs";
      options = [
        "subvol=persist"
        "compress=zstd:1"
        "noatime"
        "discard=async"
        "space_cache=v2"
      ];
      neededForBoot = true;
    };
    # boot
    "/boot" = {
      device = "/dev/disk/by-uuid/601B-12CD";
      fsType = "vfat";
      neededForBoot = true;
    };
    # efi
    "/efi" = {
      device = "/dev/disk/by-uuid/6A71-B54B";
      fsType = "vfat";
      neededForBoot = true;
    };
    # shigure
    "/mnt/shigure" = {
      device = "/dev/disk/by-uuid/CC76855576854166";
      fsType = "ntfs";
      options = [
        "rw"
        "uid=1000"
        "gid=100"
        "umask=022"
      ];
    };
  };

  boot = {
    # consoleLogLevel = 0;
    # kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
    kernelParams = [
      "mitigations=off"
      "preempt=full"
      "quiet"
      "udev.log_level=3"
    ];

    kernelModules = [];
    extraModulePackages = [];

    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [];
      systemd.enable = true;
      supportedFilesystems = ["btrfs"];
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    loader = {
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/efi";
      systemd-boot = {
        enable = lib.mkForce (!config.boot.lanzaboote.enable);
        configurationLimit = 1;
        consoleMode = "max";
        editor = false;
      };
    };
  };

  hardware = {
    enableRedistributableFirmware = true;
  };

  environment = {
    binsh = "${pkgs.zsh}/bin/zsh";
    pathsToLink = ["/share/zsh"];
    shells = with pkgs; [zsh];
    systemPackages = with pkgs; [
      qemu
      (qemu.override {
        gtkSupport = true;
        openGLSupport = true;
        virglSupport = true;
      })
      git
      ntfs3g
      sbctl
      qemu_kvm
    ];
  };

  # fonts
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
      enable = lib.mkDefault true;
      defaultFonts = {
        monospace = ["M PLUS 1 Code"];
        emoji = ["Noto Color Emoji"];
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

  # locales
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

  # programs
  programs = {
    command-not-found.enable = false;
    zsh.enable = true;
    fuse.userAllowOther = true; # impermanence
    coolercontrol.enable = true; # fancontrol
    nix-index-database.comma.enable = true;
  };

  # security
  security = {
    sudo.wheelNeedsPassword = false;
  };

  # services
  services = {
    journald.extraConfig = lib.mkForce "";
    udev.extraRules = ''
      SUBSYSTEM=="usb", ATTRS{idVendor}=="0c45", ATTRS{idProduct}=="636d", MODE="0660", GROUP="usbpassthrough", TAG+="uaccess"
    '';
  };

  # users
  users = {
    mutableUsers = false;
    users.root.hashedPasswordFile = "/persist/passwords/root";
    users.lis = {
      isNormalUser = true;
      shell = pkgs.zsh;
      group = "users";
      extraGroups = [
        "wheel"
        "video"
        "audio"
        "realtime"
        "input"
        "kvm"
        "usbpassthrough"
      ];
      hashedPasswordFile = "/persist/passwords/lis";
      openssh.authorizedKeys.keys = flake.people.lis.sshKeys;
    };
  };

  environment.persistence."/persist".users.lis = {
    directories = [
      "downloads"
      "pictures"
      "projects"
      "documents"
      "videos"
      ".gnupg"
      ".ssh"
      ".vscode"
      ".var"
      ".local/share/keyrings"
      ".local/share/direnv"
      ".local/share/wallpapers"
      ".local/share/TelegramDesktop"
      ".local/share/flatpak"
      ".config/spotify"
      ".config/vesktop"
      ".cache/tealdeer"
      ".cache/nix"
      ".cache/starship"
      ".cache/nix-index"
      ".cache/flatpak"
      ".mozilla"
      ".cache/mozilla"
    ];
    files = [".zsh_history"];
  };

  # time
  time.timeZone = "Europe/Stockholm";

  system.stateVersion = "23.11";
}
