_: {
  flake.modules.nixos.shell = {
    programs.zsh.enable = true;
  };

  flake.modules.hjem.shell = {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.meta) getExe;
  in {
    packages = with pkgs; [
      btop
      direnv
      eza
      fzf
      starship
      tealdeer
    ];

    rum.programs.zsh = {
      enable = true;

      plugins.zsh-autosuggestions.source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";

      # HJEM-RUM CONCATENATES THIS DIRECTLY AFTER THE PLUGIN COMMANDS
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
