{pkgs, ...}: {
  hardware = {
    graphics.enable = true;

    nvidia = {
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
    };
  };

  services = {
    xserver.videoDrivers = ["nvidia"];

    desktopManager = {
      plasma6.enable = true;
      plasma-login-manager.enable = true;
      defaultSession = "plasma";
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    steam
    gamescope
    mangohud
    protonup-qt
    firefox
  ];
}
