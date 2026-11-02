_: {
  flake.modules.nixos.shell = {
    programs.zsh.enable = true;
  };

  flake.modules.hjem.shell = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.meta) getExe;
    inherit (lib.modules) mkIf;
  in {
    packages = with pkgs; [
      btop
      direnv
      eza
      fzf
      starship
      tealdeer
    ];

    files.".zlogin".text = mkIf config.rum.programs.zsh.enable config.rum.programs.zsh.loginConfig;

    rum.programs.zsh = {
      enable = true;

      plugins.zsh-autosuggestions.source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";

      initConfig =
        "\n"
        +
        /*
        zsh
        */
        ''
          eval "$(${getExe pkgs.starship} init zsh)"
          eval "$(${getExe pkgs.direnv} hook zsh)"
        '';
    };
  };
}
