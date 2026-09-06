_: {
  flake.modules.nixos.onepassword = {
    programs._1password-gui.enable = true;
  };

  flake.modules.hjem.onepassword = {
    config,
    lib,
    osConfig,
    ...
  }: let
    inherit (lib.modules) mkIf;
  in {
    files.".ssh/config" = mkIf osConfig.programs._1password-gui.enable {
      text =
        /*
        ssh_config
        */
        ''
          Host *
            IdentityAgent "${config.directory}/.1password/agent.sock"
        '';
    };
  };
}
