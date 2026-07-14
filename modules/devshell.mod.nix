{
  inputs,
  lib,
  ...
}: let
  inherit (lib.strings) fileContents;
in {
  imports = [inputs.git-hooks.flakeModule];

  perSystem = {
    config,
    pkgs,
    ...
  }: let
    pani = pkgs.writeShellScriptBin "pani" (fileContents ../scripts/pani.sh);
  in {
    pre-commit.settings.hooks = {
      alejandra.enable = true;
      deadnix.enable = true;
      nil.enable = true;
      statix.enable = true;
    };

    devShells.default = pkgs.mkShell {
      name = "gyaru/nix-config";
      packages = with pkgs; [
        alejandra
        deadnix
        fd
        git
        nil
        nix-output-monitor
        pani
        shellcheck
        statix
      ];

      shellHook =
        /*
        bash
        */
        ''
          ${config.pre-commit.installationScript}
          echo "lis' nix-config environment"
        '';
    };
  };
}
