{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe;
in {
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
      enp5s0.allowedTCPPorts = [22 445];
      tailscale0.allowedTCPPorts = [
        22
        139
        445
      ];
    };
  };

  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.age.secrets.k3s-token.path;
    disable = ["traefik" "servicelb"];

    extraKubeletConfig.seccompDefault = true;

    extraFlags = [
      "--node-ip=192.168.1.240"
      "--advertise-address=192.168.1.240"
      "--flannel-iface=enp5s0"
      "--tls-san=127.0.0.1"
      "--tls-san=${config.networking.hostName}"
      "--write-kubeconfig-mode=600"
    ];
  };

  systemd.services = {
    k3s = {
      after = singleton "network-addresses-enp5s0.service";
      requires = singleton "network-addresses-enp5s0.service";

      unitConfig.RequiresMountsFor = singleton "/mlem/media";

      serviceConfig = {
        ManagedOOMPreference = "avoid";
        OOMScoreAdjust = -900;
      };
    };

    flux-sops-key = {
      description = "Install the Flux SOPS decryption key";
      wantedBy = singleton "multi-user.target";
      after = ["k3s.service" "agenix.service"];
      requires = singleton "k3s.service";
      partOf = singleton "k3s.service";
      restartTriggers = singleton config.age.secrets.flux-sops-age-key.file;
      environment.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "10s";
        UMask = "0077";
        LoadCredential = "age-key:${config.age.secrets.flux-sops-age-key.path}";
      };
      script =
        /*
        bash
        */
        ''
          set -euo pipefail
          ${getExe pkgs.kubectl} create namespace flux-system --dry-run=client --output=yaml \
            | ${getExe pkgs.kubectl} apply --server-side --field-manager=nixos-flux-secrets --filename=-
          ${getExe pkgs.kubectl} --namespace=flux-system create secret generic sops-age \
            --from-file=age.agekey="$CREDENTIALS_DIRECTORY/age-key" --dry-run=client --output=yaml \
            | ${getExe pkgs.kubectl} apply --server-side --field-manager=nixos-flux-secrets --force-conflicts --filename=-
        '';
    };
  };

  environment = {
    systemPackages = with pkgs; [
      age
      fluxcd
      kubectl
      runc
      sops
    ];
  };

  # SONOFF DONGLE
  services.udev.extraRules =
    /*
    udev
    */
    ''
      SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee", MODE="0660", GROUP="dialout"
    '';
}
