{lib, ...}: let
  inherit (lib.strings) fileContents;
in {
  perSystem = {pkgs, ...}: {
    checks.cluster = pkgs.runCommand "cluster-check" {
      nativeBuildInputs = with pkgs; [jq kustomize yq-go];
      src = ../k3s;
      renderer = ../scripts/render-cluster.sh;
    } (fileContents ../scripts/check-cluster.sh);
  };
}
