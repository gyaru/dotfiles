{
  lib,
  pkgs,
  ...
}: let
  inherit (lib.lists) singleton;
in {
  environment = {
    sessionVariables.KWIN_DRM_DEVICES = "/dev/dri/nvidia-card";

    systemPackages = with pkgs; [
      steam
      gamescope
      mangohud
      protonup-qt
      firefox
    ];
  };

  hardware = {
    graphics.enable = true;

    nvidia = {
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
    };
  };

  services = {
    udev.extraRules = ''
      SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:01:00.0", DRIVERS=="nvidia", SYMLINK+="dri/nvidia-card"
    '';

    xserver.videoDrivers = ["nvidia"];

    displayManager.plasma-login-manager.enable = true;

    desktopManager = {
      plasma6.enable = true;
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  systemd.tmpfiles.rules =
    singleton
    <| "L+ /var/lib/AccountsService/users/lis - - - - ${
      pkgs.writeText "accountsservice-lis" ''
        [User]
        SystemAccount=true
      ''
    }";
}
