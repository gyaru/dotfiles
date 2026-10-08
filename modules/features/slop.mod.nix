{self, ...}: {
  flake.modules.nixos.slop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.attrsets) genAttrs;
    inherit (lib.lists) singleton;
    inherit (lib.meta) getExe;
    inherit (lib.modules) mkIf;
    inherit (lib.options) mkEnableOption mkOption;
    inherit (lib.strings) escapeShellArgs;
    inherit (lib.types) bool listOf package port str;

    cfg = config.modules.slop.server;
  in {
    options.modules.slop.server = {
      enable = mkEnableOption "the T3 Code server with bundled coding agents";

      package = mkOption {
        type = package;
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.slop-server;
        description = "Server and coding-agent bundle to run.";
      };

      host = mkOption {
        type = str;
        default = "0.0.0.0";
        description = "Address on which the T3 Code server listens.";
      };

      port = mkOption {
        type = port;
        default = 3773;
        description = "T3 Code HTTP and WebSocket port.";
      };

      user = mkOption {
        type = str;
        default = "slop";
        description = "Dedicated system user for the server, projects, and agent credentials.";
      };

      openFirewall = mkOption {
        type = bool;
        default = false;
        description = "Open the server port in the firewall.";
      };

      interfaces = mkOption {
        type = listOf str;
        default = [];
        description = "Interfaces on which to open the port; empty means all interfaces.";
      };
    };

    config = {
      environment.systemPackages = mkIf cfg.enable <| singleton cfg.package;

      users.groups.${cfg.user} = mkIf cfg.enable {};

      users.users.${cfg.user} = mkIf cfg.enable {
        isSystemUser = true;
        group = cfg.user;
        home = "/var/lib/${cfg.user}";
        createHome = true;
        homeMode = "0700";
        shell = pkgs.bashInteractive;
        packages = singleton pkgs.git;
      };

      networking.firewall.allowedTCPPorts = mkIf (cfg.enable && cfg.openFirewall && cfg.interfaces == []) <| singleton cfg.port;

      networking.firewall.interfaces =
        mkIf (cfg.enable && cfg.openFirewall)
        <| genAttrs cfg.interfaces (_: {
          allowedTCPPorts = singleton cfg.port;
        });

      systemd.services.slop = mkIf cfg.enable {
        description = "T3 Code server";
        wantedBy = singleton "multi-user.target";
        wants = singleton "network-online.target";
        after = singleton "network-online.target";
        path = [cfg.package pkgs.bashInteractive pkgs.coreutils pkgs.git pkgs.openssh pkgs.nix];

        environment = {
          HOME = config.users.users.${cfg.user}.home;
          SHELL = getExe config.users.users.${cfg.user}.shell;
        };

        serviceConfig = {
          User = cfg.user;
          Group = cfg.user;
          WorkingDirectory = config.users.users.${cfg.user}.home;
          ExecStart = escapeShellArgs [
            (getExe cfg.package)
            "serve"
            "--host"
            cfg.host
            "--port"
            (toString cfg.port)
          ];
          Restart = "on-failure";
          RestartSec = 5;
          UMask = "0077";
        };
      };
    };
  };
}
