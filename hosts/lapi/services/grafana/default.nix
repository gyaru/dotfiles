{
  config,
  flake,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.lists) singleton;
  inherit (lib.strings) toJSON;
  kubeTokenFile = "/var/lib/${config.services.prometheus.stateDir}/k3s-token";
  kubeCAFile = "/var/lib/${config.services.prometheus.stateDir}/k3s-ca.crt";
  kubeConfigFile =
    pkgs.writeText "prometheus-kubeconfig.json"
    <| toJSON {
      apiVersion = "v1";
      kind = "Config";
      clusters = singleton {
        name = "k3s";
        cluster = {
          certificate-authority = kubeCAFile;
          server = "https://127.0.0.1:6443";
        };
      };
      users = singleton {
        name = "prometheus";
        user.tokenFile = kubeTokenFile;
      };
      contexts = singleton {
        name = "prometheus@k3s";
        context = {
          cluster = "k3s";
          user = "prometheus";
        };
      };
      current-context = "prometheus@k3s";
    };
in {
  imports = singleton flake.modules.nixos.prometheus-endpointslice;

  networking.firewall.extraCommands =
    /*
    bash
    */
    ''
      iptables --append nixos-fw --protocol tcp --dport 3000 --source 192.168.1.0/24 --jump nixos-fw-accept
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
        security.secret_key = "$__file{${config.services.grafana.dataDir}/secret-key}";
      };
      provision = {
        enable = true;
        datasources.settings = {
          apiVersion = 1;
          datasources = singleton {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${toString config.services.prometheus.port}";
            uid = "prometheus";
            isDefault = true;
          };
        };
        dashboards.settings = {
          apiVersion = 1;
          providers = singleton {
            name = "Lapi";
            folder = "Lapi";
            options.path = ./dashboards;
          };
        };
      };
    };

    prometheus = {
      enable = true;
      checkConfig = "syntax-only";
      listenAddress = "127.0.0.1";
      port = 9092;
      retentionTime = "30d";
      exporters = {
        process = {
          enable = true;
          listenAddress = "127.0.0.1";
          extraFlags = singleton "--threads=false";
          settings.process_names = singleton {
            name = "{{.ExeBase}}";
            cmdline = singleton ".+";
          };
        };

        node = {
          enable = true;
          listenAddress = "127.0.0.1";
          enabledCollectors = singleton "systemd";
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
          static_configs = singleton {
            targets = singleton "127.0.0.1:${toString config.services.prometheus.port}";
          };
        }
        {
          job_name = "node";
          static_configs = singleton {
            targets = singleton "127.0.0.1:${toString config.services.prometheus.exporters.node.port}";
          };
        }
        {
          job_name = "nvidia";
          static_configs = singleton {
            targets = singleton "127.0.0.1:${toString config.services.prometheus.exporters.nvidia-gpu.port}";
          };
        }
        {
          job_name = "smartctl";
          static_configs = singleton {
            targets = singleton "127.0.0.1:${toString config.services.prometheus.exporters.smartctl.port}";
          };
        }
        {
          job_name = "zfs";
          static_configs = singleton {
            targets = singleton "127.0.0.1:${toString config.services.prometheus.exporters.zfs.port}";
          };
        }
        {
          job_name = "processes";
          static_configs = singleton {
            targets = singleton "127.0.0.1:${toString config.services.prometheus.exporters.process.port}";
          };
        }
        {
          job_name = "k3s";
          scheme = "https";
          bearer_token_file = kubeTokenFile;
          tls_config.ca_file = kubeCAFile;
          static_configs = singleton {
            targets = singleton "127.0.0.1:6443";
          };
        }
        {
          job_name = "kubelet";
          scheme = "https";
          metrics_path = "/api/v1/nodes/${config.networking.hostName}/proxy/metrics";
          bearer_token_file = kubeTokenFile;
          tls_config.ca_file = kubeCAFile;
          static_configs = singleton {
            targets = singleton "127.0.0.1:6443";
          };
        }
        {
          job_name = "cadvisor";
          scheme = "https";
          metrics_path = "/api/v1/nodes/${config.networking.hostName}/proxy/metrics/cadvisor";
          bearer_token_file = kubeTokenFile;
          tls_config.ca_file = kubeCAFile;
          static_configs = singleton {
            targets = singleton "127.0.0.1:6443";
          };
        }
        {
          job_name = "kube-state-metrics";
          static_configs = singleton {
            targets = singleton "10.43.0.240:8080";
          };
        }
        {
          job_name = "tailscale-proxies";
          kubernetes_sd_configs = singleton {
            role = "endpointslice";
            kubeconfig_file = "${kubeConfigFile}";
            namespaces.names = singleton "tailscale";
          };
          relabel_configs = [
            {
              source_labels = singleton "__meta_kubernetes_service_label_tailscale_com_metrics_target";
              regex = ".+";
              action = "keep";
            }
            {
              source_labels = singleton "__meta_kubernetes_endpointslice_port_name";
              regex = "metrics";
              action = "keep";
            }
            {
              source_labels = singleton "__meta_kubernetes_service_label_ts_proxy_parent_name";
              target_label = "proxy";
            }
            {
              source_labels = singleton "__meta_kubernetes_service_label_ts_proxy_parent_namespace";
              target_label = "proxy_namespace";
            }
            {
              source_labels = singleton "__meta_kubernetes_service_label_ts_proxy_type";
              target_label = "proxy_type";
            }
          ];
        }
      ];
    };
  };

  systemd.timers.k3s-prometheus-credentials = {
    wantedBy = singleton "timers.target";
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "30min";
    };
  };

  systemd.services = {
    k3s-prometheus-credentials = {
      description = "Sync k3s credentials for Prometheus";
      before = singleton "prometheus.service";
      wantedBy = singleton "multi-user.target";
      after = singleton "k3s.service";
      requires = singleton "k3s.service";
      unitConfig.StartLimitIntervalSec = 0;
      path = singleton pkgs.kubectl;
      environment.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
      serviceConfig = {
        Type = "oneshot";
        UMask = "0077";
        Restart = "on-failure";
        RestartSec = "10s";
      };
      script =
        /*
        bash
        */
        ''
          set -euo pipefail
          install --directory --mode=0750 --owner=prometheus --group=prometheus /var/lib/${config.services.prometheus.stateDir}
          token_file="$(mktemp /var/lib/${config.services.prometheus.stateDir}/.k3s-token.XXXXXX)"
          ca_file="$(mktemp /var/lib/${config.services.prometheus.stateDir}/.k3s-ca.XXXXXX)"
          trap 'rm --force "$token_file" "$ca_file"' EXIT
          kubectl --namespace=monitoring create token prometheus --duration=24h > "$token_file"
          kubectl config view --raw --minify --output=jsonpath='{.clusters[0].cluster.certificate-authority-data}' \
            | base64 --decode > "$ca_file"
          test -s "$token_file"
          test -s "$ca_file"
          chmod 0400 "$token_file" "$ca_file"
          chown prometheus:prometheus "$token_file" "$ca_file"
          mv --force "$ca_file" ${kubeCAFile}
          mv --force "$token_file" ${kubeTokenFile}
        '';
    };

    grafana-secret-key = {
      description = "Generate Grafana secret key";
      requiredBy = singleton "grafana.service";
      before = singleton "grafana.service";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0077";
      };
      script =
        /*
        bash
        */
        ''
          install --directory --mode=0750 --owner=grafana --group=grafana ${config.services.grafana.dataDir}
          if [ ! -s ${config.services.grafana.dataDir}/secret-key ]; then
            ${pkgs.openssl}/bin/openssl rand -hex 32 > ${config.services.grafana.dataDir}/secret-key
          fi
          chmod 0400 ${config.services.grafana.dataDir}/secret-key
          chown grafana:grafana ${config.services.grafana.dataDir}/secret-key
        '';
    };

    prometheus = {
      after = singleton "k3s-prometheus-credentials.service";
      requires = singleton "k3s-prometheus-credentials.service";
    };
  };
}
