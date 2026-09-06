{
  inputs,
  lib,
  ...
}: let
  inherit (lib.lists) singleton;
in {
  imports = singleton inputs.git-hooks.flakeModule;

  perSystem = {
    config,
    pkgs,
    ...
  }: {
    pre-commit.settings.hooks = {
      alejandra.enable = true;
      deadnix.enable = true;
      nil.enable = true;
      statix.enable = true;
      shellcheck.enable = true;
    };

    devShells.default = pkgs.mkShell {
      name = "gyaru/nix-config";
      packages = with pkgs; [
        alejandra
        config.packages.pani
        deadnix
        dix
        fd
        fluxcd
        git
        jq
        kubectl
        kustomize
        nh
        nil
        nix-output-monitor
        shellcheck
        statix
        yq-go
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
