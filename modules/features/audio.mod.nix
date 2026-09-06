_: {
  flake.modules.nixos.audio = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.lists) singleton;
    inherit (lib.modules) mkIf;
    inherit (lib.options) mkEnableOption mkOption;
    inherit (lib.types) nullOr str;
    inherit (lib.types.ints) positive;

    cfg = config.modules.audio;
    preferDevice = name: {
      "monitor.alsa.rules" = singleton {
        matches = singleton {"node.name" = name;};
        actions.update-props = {
          "priority.session" = 1500;
          "priority.driver" = 1500;
        };
      };
    };
  in {
    options.modules.audio = {
      enable = mkEnableOption "PipeWire audio";

      defaultSink = mkOption {
        type = nullOr str;
        default = null;
        description = "Preferred audio sink node name.";
        example = "alsa_output.pci-0000_00_1f.3.analog-stereo";
      };

      defaultSource = mkOption {
        type = nullOr str;
        default = null;
        description = "Preferred audio source node name.";
        example = "alsa_input.pci-0000_00_1f.3.analog-stereo";
      };

      sampleRate = mkOption {
        type = positive;
        default = 48000;
        description = "Default sample rate in Hz.";
      };

      quantumSize = mkOption {
        type = positive;
        default = 1024;
        description = "Default buffer size in samples.";
      };

      extraConfig = mkOption {
        inherit (pkgs.formats.json {}) type;
        default = {};
        description = "Additional PipeWire context properties.";
      };
    };

    config = {
      services.pipewire = {
        enable = mkIf cfg.enable true;
        socketActivation = mkIf cfg.enable false;
        alsa.enable = mkIf cfg.enable true;
        alsa.support32Bit = mkIf cfg.enable true;
        jack.enable = mkIf cfg.enable true;
        pulse.enable = mkIf cfg.enable true;
        wireplumber.enable = mkIf cfg.enable true;

        extraConfig.pipewire."10-clock-rate"."context.properties" =
          mkIf cfg.enable
          <| {
            "default.clock.rate" = cfg.sampleRate;
            "default.clock.quantum" = cfg.quantumSize;
            "default.clock.min-quantum" = 32;
            "default.clock.max-quantum" = 8192;
          }
          // cfg.extraConfig;

        wireplumber.extraConfig = {
          "10-default-sink" = mkIf (cfg.enable && cfg.defaultSink != null) <| preferDevice cfg.defaultSink;
          "10-default-source" = mkIf (cfg.enable && cfg.defaultSource != null) <| preferDevice cfg.defaultSource;
        };
      };

      security.rtkit.enable = mkIf cfg.enable true;

      systemd.services.rtkit-daemon.serviceConfig.ExecStart = mkIf cfg.enable [
        ""
        "${pkgs.rtkit}/libexec/rtkit-daemon --our-realtime-priority=95 --max-realtime-priority=90"
      ];

      systemd.user.services = {
        pipewire.wantedBy = mkIf cfg.enable <| singleton "default.target";
        pipewire-pulse.wantedBy = mkIf cfg.enable <| singleton "default.target";
      };
    };
  };
}
