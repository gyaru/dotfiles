_: {
  flake.modules.hjem.desktop-apps = {pkgs, ...}: {
    packages = with pkgs; [
      flatpak
      gpu-screen-recorder
      imv
      kooha
      mpv
      obs-studio
      spotify
      telegram-desktop
      vesktop
    ];
  };
}
