{lib, ...}: let
  inherit (lib.strings) fileContents;
in {
  perSystem = {pkgs, ...}: {
    checks.cluster = pkgs.runCommand "cluster-check" {
      nativeBuildInputs = with pkgs; [jq kustomize yq-go];
      src = ../k3s;
      renderer = ../scripts/render-cluster.sh;
    } (fileContents ../scripts/check-cluster.sh);

    checks.flux-migration = pkgs.runCommand "flux-migration-check" {
      nativeBuildInputs = with pkgs; [git jq kustomize yq-go];
      src = ../k3s;
      scripts = ../scripts;
    } (fileContents ../scripts/test-flux-migration.sh);
  };
}
