{self, ...}: {
  flake.modules.nixos.external-gaming = {
    config,
    pkgs,
    ...
  }: {
    imports = with self.modules.nixos; [
      flatpak
      nvidia
    ];

    environment.sessionVariables.KWIN_DRM_DEVICES = "/dev/dri/nvidia-card";

    environment.systemPackages = with pkgs; [
      gamescope
      mangohud
      protonup-qt
      curseforge
      umu-launcher
      vesktop
      telegram-desktop
      firefox
      steamcmd
    ];

    hardware.graphics.enable32Bit = true;

    services = {
      udev.extraRules =
        /*
        udev
        */
        ''
          SUBSYSTEM=="drm", KERNEL=="card[0-9]*", DRIVERS=="nvidia", SYMLINK+="dri/nvidia-card"
        '';

      displayManager.plasma-login-manager.enable = true;

      desktopManager.plasma6.enable = true;
    };

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = false;
    };

    systemd.user = {
      services = {
        plasma-login.environment.KWIN_DRM_DEVICES = config.environment.sessionVariables.KWIN_DRM_DEVICES;
        speech-dispatcher.enable = false;
      };

      sockets.speech-dispatcher.enable = false;
    };
  };
}
