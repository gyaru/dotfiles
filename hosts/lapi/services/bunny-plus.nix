{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (lib.lists) singleton;
in {
  imports = singleton inputs.bunny-plus.nixosModules.bunny-controller;

  age.secrets.cloudflare-stream-output-url = {
    file = ../../../secrets/cloudflare-stream-output-url.age;
    mode = "0400";
  };

  services.bunny-controller = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 10000;
    controlSecretFile = "/var/lib/bunny-plus/control-secret";
    outputUrlFile = config.age.secrets.cloudflare-stream-output-url.path;
    maxVideoBitrateKbps = 6000;
    videoEncoder = "h264_nvenc";
    jellyfinHttpOrigin = "http://10.43.141.156:8096";
  };

  systemd.services.bunny-stream-controller = {
    after = ["tailscaled.service" "agenix-install-secrets.service"];
    restartTriggers = singleton config.age.secrets.cloudflare-stream-output-url.file;
  };

  systemd.tmpfiles.rules = singleton "d /var/lib/bunny-plus 0700 root root -";
}
