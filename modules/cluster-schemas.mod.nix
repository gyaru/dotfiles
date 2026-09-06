{
  self,
  lib,
  ...
}: let
  inherit (lib.strings) fileContents;
  inherit (lib.versions) majorMinor;
in {
  perSystem = {pkgs, ...}: {
    checks.cluster-schemas = pkgs.runCommand "cluster-schema-check" {
      nativeBuildInputs = with pkgs; [jq kubeconform kustomize yq-go];
      src = ../k3s;
      renderer = ../scripts/render-cluster.sh;
      kubernetesVersion = majorMinor self.nixosConfigurations.lapi.config.services.k3s.package.version;
      schemas = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.35.7-standalone-strict/_definitions.json";
        hash = "sha256-nbyepgQtQeNtkIskiXxO4SbhmaCkaFbNYMfcvnM4HkU=";
      };
    } (fileContents ../scripts/check-cluster-schemas.sh);
  };
}
