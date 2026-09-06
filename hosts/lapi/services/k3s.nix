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
    allowedTCPPorts = singleton 51413;
    allowedUDPPorts = singleton 51413;
    extraCommands =
      /*
      bash
      */
      ''
        iptables --append nixos-fw --protocol tcp --dport 8211 --source 192.168.1.0/24 --jump nixos-fw-accept
        iptables --append nixos-fw --protocol tcp --dport 80 --source 192.168.1.0/24 --jump nixos-fw-accept
        iptables --append nixos-fw --protocol tcp --dport 443 --source 192.168.1.0/24 --jump nixos-fw-accept
        iptables --append nixos-fw --protocol tcp --dport 6443 --source 192.168.1.0/24 --jump nixos-fw-accept
        iptables --append nixos-fw --protocol tcp --dport 8096 --source 192.168.1.0/24 --jump nixos-fw-accept
        iptables --append nixos-fw --protocol tcp --dport 5055 --source 192.168.1.0/24 --jump nixos-fw-accept
      '';
  };

  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.age.secrets.k3s-token.path;
    disable = ["traefik" "servicelb"];

    extraFlags = [
      "--tls-san=127.0.0.1"
      "--tls-san=${config.networking.hostName}"
      "--write-kubeconfig-mode=600"
    ];
  };

  systemd.services = {
    k3s.unitConfig.RequiresMountsFor = ["/mlem/media" "/mlem/seafile/data"];

    k3s.serviceConfig = {
      ManagedOOMPreference = "avoid";
      OOMScoreAdjust = -900;
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
