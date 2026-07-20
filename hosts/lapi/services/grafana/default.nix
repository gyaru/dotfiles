{
  config,
  lib,
  pkgs,
  ...
}: let
  kubeTokenFile = "/var/lib/prometheus/k3s-token";
  kubeCAFile = "/var/lib/prometheus/k3s-ca.crt";
in {
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp --dport 3000 -s 192.168.1.0/24 -j nixos-fw-accept
    iptables -A nixos-fw -p tcp --dport 9092 -s 192.168.1.0/24 -j nixos-fw-accept
  '';

  services = {
    grafana = {
      enable = true;
      settings = {
        analytics.reporting_enabled = false;
        server = {
          http_addr = "0.0.0.0";
          http_port = 3000;
          domain = config.networking.hostName;
        };
        security.secret_key = "$__file{/var/lib/grafana/secret-key}";
      };
      provision = {
        enable = true;
        datasources.settings = {
          apiVersion = 1;
          datasources = lib.lists.singleton {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:9092";
            uid = "prometheus";
            isDefault = true;
          };
        };
        dashboards.settings = {
          apiVersion = 1;
          providers = lib.lists.singleton {
            name = "Lapi";
            folder = "Lapi";
            options.path = ./dashboards;
          };
        };
      };
    };

    prometheus = {
      enable = true;
      checkConfig = false;
      listenAddress = "0.0.0.0";
      port = 9092;
      retentionTime = "30d";
      exporters = {
        node = {
          enable = true;
          listenAddress = "127.0.0.1";
          enabledCollectors = ["systemd"];
        };
        nvidia-gpu = {
          enable = true;
          listenAddress = "127.0.0.1";
        };
        smartctl = {
          enable = true;
          listenAddress = "127.0.0.1";
        };
        zfs = {
          enable = true;
          listenAddress = "127.0.0.1";
        };
      };
      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = lib.lists.singleton {
            targets = ["127.0.0.1:9092"];
          };
        }
        {
          job_name = "node";
          static_configs = lib.lists.singleton {
            targets = ["127.0.0.1:9100"];
          };
        }
        {
          job_name = "nvidia";
          static_configs = lib.lists.singleton {
            targets = ["127.0.0.1:9835"];
          };
        }
        {
          job_name = "smartctl";
          static_configs = lib.lists.singleton {
            targets = ["127.0.0.1:9633"];
          };
        }
        {
          job_name = "zfs";
          static_configs = lib.lists.singleton {
            targets = ["127.0.0.1:9134"];
          };
        }
        {
          job_name = "k3s";
          scheme = "https";
          bearer_token_file = kubeTokenFile;
          tls_config.ca_file = kubeCAFile;
          static_configs = lib.lists.singleton {
            targets = ["127.0.0.1:6443"];
          };
        }
        {
          job_name = "kubelet";
          scheme = "https";
          metrics_path = "/api/v1/nodes/lapi/proxy/metrics";
          bearer_token_file = kubeTokenFile;
          tls_config.ca_file = kubeCAFile;
          static_configs = lib.lists.singleton {
            targets = ["127.0.0.1:6443"];
          };
        }
        {
          job_name = "cadvisor";
          scheme = "https";
          metrics_path = "/api/v1/nodes/lapi/proxy/metrics/cadvisor";
          bearer_token_file = kubeTokenFile;
          tls_config.ca_file = kubeCAFile;
          static_configs = lib.lists.singleton {
            targets = ["127.0.0.1:6443"];
          };
        }
        {
          job_name = "kube-state-metrics";
          static_configs = lib.lists.singleton {
            targets = ["10.43.0.240:8080"];
          };
        }
      ];
    };
  };

  systemd.services = {
    k3s-prometheus-credentials = {
      description = "Sync k3s credentials for Prometheus";
      wantedBy = ["multi-user.target"];
      after = ["k3s.service"];
      requires = ["k3s.service"];
      path = [pkgs.k3s];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script =
        /*
        bash
        */
        ''
          kubectl --namespace monitoring wait \
            --for=jsonpath='{.data.token}' \
            secret/prometheus-token \
            --timeout=60s
          install --directory --mode=0750 --owner=prometheus --group=prometheus /var/lib/prometheus
          kubectl --namespace monitoring get secret prometheus-token \
            --output=jsonpath='{.data.token}' \
            | ${pkgs.coreutils}/bin/base64 --decode \
            > ${kubeTokenFile}
          chmod 0400 ${kubeTokenFile}
          chown prometheus:prometheus ${kubeTokenFile}
          kubectl --namespace monitoring get secret prometheus-token \
            --output=jsonpath='{.data.ca\.crt}' \
            | ${pkgs.coreutils}/bin/base64 --decode \
            > ${kubeCAFile}
          chmod 0400 ${kubeCAFile}
          chown prometheus:prometheus ${kubeCAFile}
        '';
    };

    grafana-secret-key = {
      description = "Generate Grafana secret key";
      wantedBy = ["grafana.service"];
      before = ["grafana.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script =
        /*
        bash
        */
        ''
          install --directory --mode=0750 --owner=grafana --group=grafana /var/lib/grafana
          if [ ! -s /var/lib/grafana/secret-key ]; then
            ${pkgs.openssl}/bin/openssl rand -hex 32 > /var/lib/grafana/secret-key
          fi
          chmod 0400 /var/lib/grafana/secret-key
          chown grafana:grafana /var/lib/grafana/secret-key
        '';
    };

    prometheus = {
      after = ["k3s-prometheus-credentials.service"];
      requires = ["k3s-prometheus-credentials.service"];
      serviceConfig.ReadOnlyPaths = [
        kubeCAFile
        kubeTokenFile
      ];
    };
  };
}
