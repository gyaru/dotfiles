{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) concatMapAttrs genAttrs;
  inherit (lib.lists) map singleton sort;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkForce;
  loadGuard = "${getExe pkgs.nftables} --file ${./network-guard.nft}";
  interfaceSysctls = family: settings:
    concatMapAttrs (
      setting: value:
        genAttrs (map (interface: "net.${family}.conf.${interface}.${setting}") ["all" "default" "*"]) (_: value)
    )
    settings;
in {
  networking = {
    dhcpcd.enable = false;
    nat.enable = false;

    firewall = {
      interfaces = {
        enp5s0.allowedUDPPorts = singleton config.services.tailscale.port;
        virbr0 = {
          allowedTCPPorts = [22 53 445];
          allowedUDPPorts = [53 67 config.services.tailscale.port];
        };
      };

      trustedInterfaces = mkForce ["lo" "cni0" "flannel.1"];
    };
  };

  boot.kernel.sysctl =
    interfaceSysctls "ipv4" {
      accept_redirects = 0;
      send_redirects = 0;
      accept_source_route = 0;
      bc_forwarding = 0;
      arp_ignore = 1;
      arp_announce = 2;
    }
    // interfaceSysctls "ipv6" {
      accept_redirects = 0;
      accept_source_route = -1;
      accept_ra = 0;
    }
    // {
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.rp_filter" = 0;
      "net.ipv4.conf.default.rp_filter" = 2;
      "net.ipv4.conf.*.rp_filter" = 2;
      "net.ipv4.conf.lo.rp_filter" = 0;
      "net.ipv4.conf.enp5s0.rp_filter" = 1;
      "net.ipv4.conf.all.src_valid_mark" = 1;
      "net.ipv4.conf.enp5s0.log_martians" = 1;
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.tcp_rfc1337" = 1;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
      "net.ipv6.conf.all.forwarding" = 0;
      "net.ipv6.conf.enp5s0.disable_ipv6" = 1;
    };

  services.tailscale.openFirewall = false;

  systemd.services = {
    lapi-network-guard = {
      description = "Restrict LAN and VM access to server services";
      wantedBy = singleton "sysinit.target";
      wants = singleton "network-pre.target";
      before = ["network-pre.target" "shutdown.target"];
      after = singleton "systemd-modules-load.service";
      conflicts = singleton "shutdown.target";
      unitConfig.DefaultDependencies = false;
      reloadIfChanged = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = loadGuard;
        ExecReload = loadGuard;
        ExecStop = "${getExe pkgs.nftables} destroy table inet lapi_network";
      };
    };

    network-addresses-enp5s0 = {
      requires = singleton "lapi-network-guard.service";
      after = singleton "lapi-network-guard.service";
    };
  };

  assertions = [
    {
      assertion = config.services.tailscale.port == 41641 && config.services.tailscale.interfaceName == "tailscale0";
      message = "Keep the packet guard in sync with the configured Tailscale interface and UDP port.";
    }
    {
      assertion =
        config.networking.interfaces.enp5s0.ipv4.addresses
        == singleton {
          address = "192.168.1.240";
          prefixLength = 24;
        };
      message = "Keep the packet guard in sync with Lapi's LAN address.";
    }
    {
      assertion =
        sort (a: b: a < b) config.networking.firewall.interfaces.enp5s0.allowedTCPPorts
        == [22 53 445]
        && sort (a: b: a < b) config.networking.firewall.interfaces.enp5s0.allowedUDPPorts == [53 41641]
        && config.networking.firewall.interfaces.enp5s0.allowedTCPPortRanges == []
        && config.networking.firewall.interfaces.enp5s0.allowedUDPPortRanges == [];
      message = "LAN may expose only SSH, SMB, DNS and encrypted Tailscale transport.";
    }
    {
      assertion = !config.networking.nat.enable && !config.services.dnsmasq.enable && !config.services.hostapd.enable;
      message = "Lapi must use the upstream router instead of providing LAN routing, DHCP or Wi-Fi.";
    }
    {
      assertion = !config.services.miniupnpd.enable;
      message = "Lapi must not offer automatic public port mappings.";
    }
    {
      assertion =
        config.networking.firewall.allowedTCPPorts
        == []
        && config.networking.firewall.allowedUDPPorts == []
        && config.networking.firewall.allowedTCPPortRanges == []
        && config.networking.firewall.allowedUDPPortRanges == [];
      message = "Open Lapi services on explicit private interfaces, never globally.";
    }
  ];
}
