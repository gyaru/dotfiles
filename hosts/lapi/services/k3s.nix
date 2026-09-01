{
  pkgs,
  config,
  ...
}: {
  age.secrets.flux-sops-age-key = {
    file = ../../../secrets/flux-sops-age-key.age;
    mode = "0400";
    owner = "root";
    group = "root";
  };

  networking.firewall = {
    trustedInterfaces = [
      "cni0"
      "flannel.1"
    ];
    interfaces = {
      eno1 = {
        allowedTCPPorts = [
          22
          139
          445
          5357
          27036
          27037
        ];
        allowedUDPPorts = [
          137
          138
          3702
          27031
          27032
          27033
          27034
          27035
          27036
        ];
      };
      tailscale0.allowedTCPPorts = [
        22
        139
        445
      ];
    };
    allowedTCPPorts = [51413]; # torrent
    allowedUDPPorts = [51413]; # torrent
    extraCommands = ''
      iptables -A nixos-fw -p tcp --dport 8211 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 80 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 443 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 6443 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 8096 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 5055 -s 192.168.1.0/24 -j nixos-fw-accept
    '';
  };

  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.age.secrets.k3s-token.path;
    extraFlags = toString [
      "--tls-san=127.0.0.1"
      "--tls-san=${config.networking.hostName}"
      "--disable=traefik"
      "--disable=servicelb"
      "--write-kubeconfig-mode=600"
    ];
  };

  systemd.services.k3s.serviceConfig = {
    ManagedOOMPreference = "avoid";
    OOMScoreAdjust = -900;
  };

  environment = {
    systemPackages = with pkgs; [
      age
      fluxcd
      k3s
      kubectl
      runc
      sops
    ];
  };

  # sonoff dongle
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee", MODE="0660", GROUP="dialout"
  '';
}
