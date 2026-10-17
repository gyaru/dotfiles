_: {
  flake.modules.nixos.ntopng = {
    config,
    lib,
    ...
  }: let
    inherit (lib.lists) singleton;
  in {
    services.ntopng = {
      enable = true;
      httpPort = 3002;
      extraConfig =
        /*
        conf
        */
        ''
          --community
          --https-port=0
          --dns-mode=2
        '';
    };

    networking.firewall = {
      interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = singleton config.services.ntopng.httpPort;

      extraCommands =
        /*
        bash
        */
        ''
          ip46tables --insert nixos-fw --protocol tcp --dport ${toString config.services.ntopng.httpPort} ! --in-interface ${config.services.tailscale.interfaceName} --jump nixos-fw-refuse
        '';
    };

    systemd.services.ntopng = {
      requires = singleton "firewall.service";
      wants = singleton "network-online.target";
      after = ["network-online.target" "firewall.service" "tailscaled.service"];
      serviceConfig = {
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "full";
        Restart = "on-failure";
        RestartSec = 5;
        UMask = "0077";
      };
    };
  };
}
