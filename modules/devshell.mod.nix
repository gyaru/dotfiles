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
    pre-commit.settings.excludes = singleton "^\\.tack/default\\.nix$";

    pre-commit.settings.hooks = {
      alejandra.enable = true;
      deadnix.enable = true;
      nil.enable = true;
      statix = {
        enable = true;
        settings.ignore = singleton ".tack/default.nix";
      };
      shellcheck.enable = true;
    };

    devShells.default = pkgs.mkShell {
      name = "gyaru/nix-config";
      packages = with pkgs; [
        alejandra
        config.packages.pani
        config.packages.tack
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
        skopeo
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
