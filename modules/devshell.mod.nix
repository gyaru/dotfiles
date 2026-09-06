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
        deadnix
        fd
        git
        jq
        fluxcd
        kubectl
        kustomize
        yq-go
        nil
        nix-output-monitor
        nh
        config.packages.pani
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
