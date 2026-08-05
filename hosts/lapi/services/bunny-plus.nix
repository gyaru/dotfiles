{
  flake,
  lib,
  pkgs,
  ...
}: {
  services.caddy = {
    enable = true;
    virtualHosts."api.bunny.plus".extraConfig = ''
      reverse_proxy 192.168.1.240:30080
    '';
  };

  systemd.services.bunny-stream-controller = {
    description = "Bunny+ host stream controller";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "tailscaled.service"];
    wants = ["network-online.target"];
    unitConfig.ConditionPathExists = [
      "/var/lib/bunny-plus/control-secret"
      "/var/lib/bunny-plus/gon-publisher-password"
    ];

    environment = {
      BUNNY_CONTROLLER_HOST = "0.0.0.0";
      BUNNY_CONTROLLER_PORT = "10000";
      BUNNY_OUTPUT_PASSWORD_CREDENTIAL = "1";
      BUNNY_OUTPUT_URL = "rtmp://gon:1935/bunny-plus?user=publisher";
      BUNNY_VIDEO_ENCODER = "h264_nvenc";
    };

    serviceConfig = {
      CapabilityBoundingSet = "";
      DeviceAllow = [
        "/dev/nvidia0 rw"
        "/dev/nvidiactl rw"
        "/dev/nvidia-modeset rw"
        "/dev/nvidia-uvm rw"
        "/dev/nvidia-uvm-tools rw"
        "/dev/nvidia-caps/nvidia-cap1 rw"
        "/dev/nvidia-caps/nvidia-cap2 rw"
      ];
      DevicePolicy = "closed";
      DynamicUser = true;
      ExecStart = lib.getExe flake.packages.${pkgs.stdenv.hostPlatform.system}.bunny-controller;
      LoadCredential = [
        "control-secret:/var/lib/bunny-plus/control-secret"
        "publisher-password:/var/lib/bunny-plus/gon-publisher-password"
      ];
      LockPersonality = true;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      Restart = "on-failure";
      RestartSec = 5;
      RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
      RestrictRealtime = true;
      SupplementaryGroups = ["video" "render"];
      SystemCallArchitectures = "native";
      UMask = "0077";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/bunny-plus 0700 root root -"
  ];
}
