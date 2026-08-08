{
  config,
  flake,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    flake.nixosModules.base
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.kernel.sysctl."kernel.unprivileged_userns_clone" = lib.mkForce 0;

  environment.systemPackages = lib.lists.singleton pkgs.gitMinimal;

  networking.firewall = {
    enable = true;
    allowPing = false;
    allowedTCPPorts = [
      80
      443
      1935
      8554
      8888
      8889
    ];
    allowedUDPPorts = [
      8189
      8890
    ];
    interfaces.tailscale0.allowedTCPPorts = config.services.openssh.ports ++ [9997];
    logRefusedConnections = false;
    logReversePathDrops = true;
  };
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  nix = {
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "flakes"
        "nix-command"
        "pipe-operators"
      ];
      trusted-users = [
        "root"
        "lis"
      ];
    };
  };

  services = {
    caddy = {
      enable = true;
      virtualHosts."gon.bunny.plus".extraConfig = ''
        handle /__bunny/control {
          reverse_proxy 127.0.0.1:10000
        }
        handle {
          reverse_proxy 127.0.0.1:8888
        }
      '';
    };

    mediamtx = {
      enable = true;
      settings = {
        api = true;
        hlsVariant = "mpegts";
        authInternalUsers = [
          {
            user = "publisher";
            pass = "sha256:Yb1sV/UCfydcnF8Ocb9mCnwdMH4l3bqQsmBQ7O1R7Dw=";
            permissions = lib.lists.singleton {action = "publish";};
          }
          {
            user = "controller";
            ips = [
              "127.0.0.1"
              "::1"
            ];
            permissions = lib.lists.singleton {
              action = "publish";
              path = "bunny-plus";
            };
          }
          {
            user = "any";
            permissions = [
              {action = "read";}
              {action = "playback";}
            ];
          }
          {
            user = "any";
            ips = [
              "127.0.0.1"
              "::1"
              "100.64.0.0/10"
            ];
            permissions = lib.lists.singleton {action = "api";};
          }
        ];
        paths = {
          bunny-plus = {
            alwaysAvailable = true;
            alwaysAvailableFile = "/var/lib/bunny-plus-media/offline.mp4";
            overridePublisher = true;
          };
          all_others = {};
        };
        rtspTransports = ["tcp"];
        webrtcAdditionalHosts = ["gon.bunny.plus"];
      };
    };

    openssh = {
      enable = true;
      openFirewall = false;
      settings = {
        AllowUsers = ["lis"];
        DisableForwarding = true;
        KbdInteractiveAuthentication = false;
        MaxAuthTries = 3;
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    tailscale = {
      enable = true;
      extraSetFlags = ["--accept-dns=false"];
      openFirewall = true;
    };
  };

  systemd.services.bunny-stream-controller = {
    description = "Bunny+ stream controller";
    wantedBy = ["multi-user.target"];
    after = ["mediamtx.service" "network-online.target"];
    wants = ["network-online.target"];

    environment = {
      BUNNY_CONTROLLER_HOST = "127.0.0.1";
      BUNNY_CONTROLLER_PORT = "10000";
      BUNNY_MEDIAMTX_PATH_URL = "http://127.0.0.1:9997/v3/paths/get/bunny-plus";
      BUNNY_OUTPUT_URL = "rtmp://127.0.0.1:1935/bunny-plus?user=controller";
    };

    serviceConfig = {
      DynamicUser = true;
      ExecStart = lib.getExe flake.packages.${pkgs.stdenv.hostPlatform.system}.bunny-controller;
      LoadCredential = "control-secret:/var/lib/bunny-plus/controller.env";
      LockPersonality = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      Restart = "on-failure";
      RestartSec = 5;
      RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
      RestrictRealtime = true;
      SystemCallArchitectures = "native";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/bunny-plus 0700 root root -"
    "d /var/lib/bunny-plus-media 0755 root root -"
    "z /var/lib/bunny-plus/controller.env 0600 root root -"
  ];

  security.sudo.wheelNeedsPassword = false;

  users = {
    mutableUsers = false;
    users = {
      lis = {
        isNormalUser = true;
        extraGroups = ["wheel"];
        hashedPassword = "!";
        openssh.authorizedKeys.keys = flake.people.lis.sshKeys;
      };
      root = {
        hashedPassword = "!";
      };
    };
  };

  system.stateVersion = "24.05";
}
