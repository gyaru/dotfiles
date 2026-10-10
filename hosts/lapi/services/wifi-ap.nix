{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.lists) singleton;
  lanInterface = config.networking.defaultGateway.interface;
  wifiInterface = "wlp11s0";
  passwordFile = config.age.secrets.lapi-wifi-password.path;
in {
  age.secrets.lapi-wifi-password = {
    file = ../../../secrets/lapi-wifi-password.age;
    mode = "0400";
    owner = "root";
    group = "root";
  };

  networking = {
    bridges.${lanInterface}.interfaces = singleton "eno1";
    interfaces.${lanInterface}.macAddress = "c8:7f:54:0c:b8:62";
  };

  services.hostapd = {
    enable = true;
    radios.${wifiInterface} = {
      countryCode = "SE";
      band = "5g";
      channel = 36;
      wifi4.capabilities = ["HT40+" "SHORT-GI-20" "SHORT-GI-40"];
      wifi5 = {
        operatingChannelWidth = "80";
        capabilities = singleton "SHORT-GI-80";
      };
      wifi6 = {
        enable = true;
        operatingChannelWidth = "80";
      };
      settings = {
        vht_oper_centr_freq_seg0_idx = 42;
        he_oper_centr_freq_seg0_idx = 42;
      };
      networks.${wifiInterface} = {
        ssid = "lapi";
        authentication = {
          mode = "wpa3-sae-transition";
          wpaPasswordFile = passwordFile;
          saePasswords = singleton {inherit passwordFile;};
        };
        settings.bridge = lanInterface;
      };
    };
  };

  systemd.services.hostapd = {
    after = ["network-addresses-${lanInterface}.service" "agenix-install-secrets.service"];
    requires = singleton "network-addresses-${lanInterface}.service";
    restartTriggers = singleton config.age.secrets.lapi-wifi-password.file;
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig.RestartSec = "5s";
  };

  environment.systemPackages = singleton pkgs.iw;
}
