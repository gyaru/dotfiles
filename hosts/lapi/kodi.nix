{pkgs, ...}: let
  dp3-idle-monitor = pkgs.writeShellScript "dp3-idle-monitor" ''
    TIMEOUT=300000  # 5 minutes in milliseconds
    BLANKED=0

    while true; do
      # Get idle time from KDE via D-Bus
      IDLE=$(${pkgs.dbus}/bin/dbus-send --print-reply --dest=org.kde.screensaver \
        /ScreenSaver org.freedesktop.ScreenSaver.GetSessionIdleTime 2>/dev/null | \
        grep uint32 | awk '{print $2}')

      if [ -z "$IDLE" ]; then
        sleep 5
        continue
      fi

      if [ "$IDLE" -ge "$TIMEOUT" ] && [ "$BLANKED" -eq 0 ]; then
        ${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor output.DP-3.dpms.off
        BLANKED=1
      elif [ "$IDLE" -lt "$TIMEOUT" ] && [ "$BLANKED" -eq 1 ]; then
        ${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor output.DP-3.dpms.on
        BLANKED=0
      fi

      sleep 5
    done
  '';
in {
  environment = {
    systemPackages = with pkgs; [
      (pkgs.kodi-wayland.withPackages (kodiPkgs:
        with kodiPkgs; [
          jurialmunkey
          robotocjksc
          texturemaker
        ]))
    ];

    etc = {
      "xdg/kwinrulesrc".text = ''
        [1]
        Description=Kodi on TV
        wmclass=kodi
        wmclassmatch=1
        screen=1
        screenrule=2
        fullscreen=true
        fullscreenrule=2
        skiptaskbar=true
        skiptaskbarrule=2
      '';

      "xdg/autostart/kodi-tv.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Kodi TV
        Exec=${pkgs.kodi-wayland}/bin/kodi
        X-KDE-autostart-phase=2
        OnlyShowIn=KDE;
      '';

      "xdg/kscreenlockerrc".text = ''
        [Daemon]
        Autolock=false
        LockOnResume=false
        Timeout=0
      '';

      "xdg/kwinrc".text = ''
        [Wayland]
        LockScreenAfterIdle=false
        IdleTimeout=0
      '';

      # doesn't seem to work?
      "xdg/autostart/dp3-idle-monitor.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=DP-3 Idle Monitor
        Exec=${dp3-idle-monitor}
        X-KDE-autostart-phase=2
        OnlyShowIn=KDE;
      '';
    };
  };

  boot.kernelParams = ["consoleblank=0"];
}
