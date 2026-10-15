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

    # Guest VMs get the same limited host access as physical LAN clients.
    # Cluster interfaces remain trusted for existing app/monitoring backends.
    firewall.trustedInterfaces = lib.mkForce ["lo" "cni0" "flannel.1"];
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 0;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv6.conf.${wanInterface}.disable_ipv6" = 1;
  };

  # DHCP only: AdGuard remains the LAN DNS server. Keep its existing address
  # so shares, cluster backends and clients do not need renumbering.
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

  # A separate nft table guards traffic after conntrack and before DNAT.
  # Keep the existing iptables backend for NixOS, k3s, and libvirt. Their
  # ACCEPT rules cannot override a DROP in this table, and their reloads
  # cannot remove it. Replacing only this table is an atomic transaction.
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
        # No ExecStop: stopping/reloading a firewall must not open WAN.
      };
    };

    # A failed guard must prevent both scripted interface setup and DHCP
    # from bringing up WAN, including when the NIC appears after boot.
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
