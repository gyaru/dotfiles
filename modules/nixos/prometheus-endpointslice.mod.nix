_: {
  flake.modules.nixos.prometheus-endpointslice = {lib, ...}: let
    inherit (lib.lists) singleton;
    inherit (lib.options) mkOption;
    inherit (lib.types) enum listOf nullOr submodule;
  in {
    # EXTEND THE NIXPKGS ENUM UNTIL IT INCLUDES PROMETHEUS ENDPOINTSLICE DISCOVERY
    options.services.prometheus.scrapeConfigs = mkOption {
      type =
        listOf
        <| submodule {
          options.kubernetes_sd_configs = mkOption {
            type =
              nullOr
              <| listOf
              <| submodule {
                options.role = mkOption {
                  type = enum <| singleton "endpointslice";
                };
              };
          };
        };
    };
  };
}
