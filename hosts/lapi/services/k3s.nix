{
  pkgs,
  config,
  ...
}: {
  networking.firewall = {
    trustedInterfaces = [
      "cni0"
      "flannel.1"
    ];
    allowedTCPPorts = [51413]; # torrent
    allowedUDPPorts = [51413]; # torrent
    extraCommands = ''
      iptables -A nixos-fw -p tcp --dport 80 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 443 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 6443 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 8096 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 8080 -s 192.168.1.0/24 -j nixos-fw-accept
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

  environment = {
    systemPackages = with pkgs; [
      k3s
      kubectl
      runc
    ];
  };
  # sonoff dongle
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee", MODE="0666", GROUP="dialout"
  '';
}
