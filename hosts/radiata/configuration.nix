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
    inputs.lanzaboote.nixosModules.lanzaboote
    flake.modules.nixos.amd
    flake.modules.nixos.workstation
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
      checkReversePath = "loose";
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
      dix
    ];
  };

  users.users.lis = {
    isNormalUser = true;
    shell = pkgs.zsh;
    group = "users";
    extraGroups = singleton "wheel";
  };

  programs = {
    command-not-found.enable = false;
  };

  services.tailscale = {
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
    hardwareClockInLocalTime = true;
  };

  system.stateVersion = "26.05";
}
