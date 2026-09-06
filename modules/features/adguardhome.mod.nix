{lib, ...}: let
  inherit (lib.lists) map singleton;
in {
  flake.modules.nixos.adguardhome = {config, ...}: {
    services.adguardhome = {
      enable = true;
      mutableSettings = false;
      host = "100.88.168.16";
      port = 3001;

      settings = {
        users = [];

        dns = {
          bind_hosts =
            map ({address, ...}: address) config.networking.interfaces.eno1.ipv4.addresses
            ++ singleton config.services.adguardhome.host;
          port = 53;
          upstream_dns = singleton "https://cloudflare-dns.com/dns-query";
          bootstrap_dns = ["1.1.1.1" "1.0.0.1"];
          use_private_ptr_resolvers = false;
        };

        filtering = {
          protection_enabled = true;
          filtering_enabled = true;
        };

        filters = singleton {
          enabled = true;
          id = 1;
          name = "AdGuard DNS filter";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
        };
      };
    };

    networking.firewall.interfaces = {
      eno1 = {
        allowedTCPPorts = singleton config.services.adguardhome.settings.dns.port;
        allowedUDPPorts = singleton config.services.adguardhome.settings.dns.port;
      };

      ${config.services.tailscale.interfaceName} = {
        allowedTCPPorts = [
          config.services.adguardhome.settings.dns.port
          config.services.adguardhome.port
        ];
        allowedUDPPorts = singleton config.services.adguardhome.settings.dns.port;
      };
    };

    services.tailscale.extraSetFlags = singleton "--accept-dns=false";

    systemd.services.adguardhome = {
      wants = singleton "tailscaled.service";
      after = singleton "tailscaled.service";
    };
  };
}
