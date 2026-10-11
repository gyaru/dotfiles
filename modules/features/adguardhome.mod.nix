{lib, ...}: let
  inherit (lib.lists) map singleton;
  inherit (lib.modules) mkAfter;
  inherit (lib.meta) getExe;
in {
  flake.modules.nixos.adguardhome = {
    config,
    pkgs,
    ...
  }: let
    lanInterface = config.networking.defaultGateway.interface;
  in {
    age.secrets.adguardhome-users = {
      file = ../../secrets/adguardhome-users.age;
      mode = "0400";
      owner = "root";
      group = "root";
    };

    services.adguardhome = {
      enable = true;
      mutableSettings = false;
      host = "100.88.168.16";
      port = 3001;

      settings = {
        dns = {
          bind_hosts =
            map ({address, ...}: address) config.networking.interfaces.${lanInterface}.ipv4.addresses
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
      ${lanInterface} = {
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
      after = ["tailscaled.service" "agenix-install-secrets.service"];
      restartTriggers = singleton config.age.secrets.adguardhome-users.file;
      serviceConfig.LoadCredential = singleton "adguard-users:${config.age.secrets.adguardhome-users.path}";
      preStart =
        mkAfter
        /*
        bash
        */
        ''
          set -euo pipefail
          umask 0077
          ${getExe pkgs.jq} --exit-status '
            type == "array" and length == 1
            and .[0].name == "lis"
            and (.[0].password | test("^[$]2[aby][$][0-9]{2}[$][./A-Za-z0-9]{53}$"))
          ' "$CREDENTIALS_DIRECTORY/adguard-users" > /dev/null
          ${getExe pkgs.yq-go} '.users = load(strenv(CREDENTIALS_DIRECTORY) + "/adguard-users")' "$STATE_DIRECTORY/AdGuardHome.yaml" > "$STATE_DIRECTORY/AdGuardHome.yaml.tmp"
          chmod 600 "$STATE_DIRECTORY/AdGuardHome.yaml.tmp"
          mv --force "$STATE_DIRECTORY/AdGuardHome.yaml.tmp" "$STATE_DIRECTORY/AdGuardHome.yaml"
        '';
    };
  };
}
