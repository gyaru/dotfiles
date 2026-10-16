{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.lists) singleton;
  wanInterface = "eno1";
  lanInterface = "br-lan";
  lanAddress = "192.168.1.240";
  guardService = "lapi-wan-guard.service";
  loadGuard = "${lib.getExe pkgs.nftables} --file ${./wan-guard.nft}";
  interfaceSysctls = family: settings:
    lib.concatMapAttrs (
      setting: value:
        lib.genAttrs (map (interface: "net.${family}.conf.${interface}.${setting}") ["all" "default" "*"]) (_: value)
    )
    settings;
in {
  networking = {
    interfaces.${wanInterface}.useDHCP = true;
    dhcpcd = {
      allowInterfaces = singleton wanInterface;
      extraConfig = "noipv6";
    };

    nat = {
      enable = true;
      externalInterface = wanInterface;
      internalInterfaces = singleton lanInterface;
      forwardPorts = [];
    };

    firewall.interfaces = {
      ${wanInterface}.allowedUDPPorts = singleton 68;
      ${lanInterface}.allowedUDPPorts = [67 config.services.tailscale.port];
      virbr0 = {
        allowedTCPPorts = [22 53 445];
        allowedUDPPorts = [53 67 config.services.tailscale.port];
      };
    };

    firewall.trustedInterfaces = lib.mkForce ["lo" "cni0" "flannel.1"];
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
      "net.ipv4.conf.${wanInterface}.rp_filter" = 1;
      "net.ipv4.conf.all.src_valid_mark" = 1;
      "net.ipv4.conf.${wanInterface}.log_martians" = 1;
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.tcp_rfc1337" = 1;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
      "net.ipv6.conf.all.forwarding" = 0;
      "net.ipv6.conf.${wanInterface}.disable_ipv6" = 1;
    };

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      port = 0;
      interface = singleton lanInterface;
      bind-dynamic = true;
      dhcp-authoritative = true;
      dhcp-range = "192.168.1.50,192.168.1.199,255.255.255.0,12h";
      dhcp-option = ["option:router,${lanAddress}" "option:dns-server,${lanAddress}"];
    };
  };

  services.tailscale.openFirewall = false;

  systemd.services = {
    lapi-wan-guard = {
      description = "Restrict client service access and block unsolicited WAN traffic";
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
      };
    };

    "network-addresses-${wanInterface}" = {
      requires = singleton guardService;
      after = singleton guardService;
    };
    dhcpcd = {
      requires = singleton guardService;
      after = singleton guardService;
    };
  };

  assertions = [
    {
      assertion = config.services.tailscale.port == 41641 && config.services.tailscale.interfaceName == "tailscale0";
      message = "Keep the packet guard in sync with the configured Tailscale interface and UDP port.";
    }
    {
      assertion =
        lib.sort builtins.lessThan config.networking.firewall.interfaces.${lanInterface}.allowedTCPPorts
        == [22 53 445]
        && lib.sort builtins.lessThan config.networking.firewall.interfaces.${lanInterface}.allowedUDPPorts == [53 67 41641]
        && config.networking.firewall.interfaces.${lanInterface}.allowedTCPPortRanges == []
        && config.networking.firewall.interfaces.${lanInterface}.allowedUDPPortRanges == [];
      message = "LAN may expose only SSH, SMB, DNS, DHCP and encrypted Tailscale transport.";
    }
    {
      assertion = config.networking.nat.forwardPorts == [] && config.networking.nat.dmzHost == null;
      message = "lapi must not publish WAN port forwards.";
    }
    {
      assertion = !config.services.miniupnpd.enable;
      message = "lapi must not offer automatic public port mappings.";
    }
    {
      assertion =
        config.networking.firewall.allowedTCPPorts
        == []
        && config.networking.firewall.allowedUDPPorts == []
        && config.networking.firewall.allowedTCPPortRanges == []
        && config.networking.firewall.allowedUDPPortRanges == [];
      message = "Open lapi services on explicit private interfaces, never globally.";
    }
    {
      assertion = lib.all (bridge: !(builtins.elem wanInterface bridge.interfaces)) (builtins.attrValues config.networking.bridges);
      message = "lapi WAN must never join the LAN/Wi-Fi bridge.";
    }
  ];
}
