#!/usr/bin/env bash
set -euo pipefail
: "${src:?Nix must supply the k3s source directory}" "${out:?Nix must supply the check output}"
: "${renderer:?Nix must supply the cluster renderer}"

bash "$renderer" "$src" rendered

# Validate the complete rendered resource set, including encrypted Secret envelopes.
jq --exit-status '
  def require($ok; $message): if $ok then . else error($message) end;
  def identity: [(.apiVersion | if contains("/") then split("/")[0] else "" end), .kind, (.metadata.namespace // ""), .metadata.name];
  . as $resources
  | require(
      (map(identity) | length) == (map(identity) | unique | length);
      "Duplicate Kubernetes resource")
  | require(all(.[]; .apiVersion and .kind and .metadata.name); "Incomplete resource identity")
  | require(all(.[] | select(.kind == "Deployment" and .metadata.namespace != "flux-system") | .spec.template.spec;
      all((.containers + (.initContainers // []))[]; .image | test("@sha256:[0-9a-f]{64}$")));
      "Deployment images must be pinned by digest")
  | require(all(.[] | select(.kind == "Deployment" and .metadata.namespace == "default");
      .spec.template.spec.automountServiceAccountToken == false);
      "Application pods must explicitly disable API token mounts")
  | require(all(.[] | select(.kind == "Deployment");
      if any(.spec.template.spec.volumes[]?; has("persistentVolumeClaim"))
      then .spec.replicas == 1 and .spec.strategy.type == "Recreate" else true end);
      "Single-writer deployments must use one replica and Recreate")
  | require(all(.[] | select(.kind == "PersistentVolume" or .kind == "PersistentVolumeClaim");
      .metadata.annotations."kustomize.toolkit.fluxcd.io/prune" == "disabled");
      "Persistent storage must be protected from Flux pruning")
  | require(all(.[] | select(.kind == "Deployment") | .spec.template.spec;
      if .hostNetwork == true or any(.volumes[]?; has("hostPath"))
      then .nodeSelector."kubernetes.io/hostname" == "lapi" else true end);
      "Host-bound workloads must be scheduled on lapi")
  | require(all(.[] | select(.kind == "Deployment");
      .metadata.namespace as $namespace
      | all(.spec.template.spec.volumes[]? | select(has("persistentVolumeClaim"));
      .persistentVolumeClaim.claimName as $claim
      | any($resources[]; .kind == "PersistentVolumeClaim" and .metadata.name == $claim
          and .metadata.namespace == $namespace)));
      "Deployment references a missing PVC")
  | require(any(.[]; .kind == "Namespace" and .metadata.name == "tailscale");
      "Tailscale namespace is missing")
  | true
' rendered/cluster.json

jq --exit-status '
  def identity: .metadata.namespace + "/" + .metadata.name;
  def require($ok; $message): if $ok then . else error($message) end;
  . as $owners
  | [.[].resources[] | select(.apiVersion == "kustomize.toolkit.fluxcd.io/v1" and .kind == "Kustomization")] as $reconcilers
  | require(all($reconcilers[];
      .spec.sourceRef.kind == "GitRepository" and .spec.sourceRef.name == "flux-system"
      and (.spec.sourceRef.namespace // .metadata.namespace) == "flux-system");
      "Renderer requires the local flux-system GitRepository")
  | require(all($reconcilers[]; .metadata.namespace as $namespace
      | all(.spec.dependsOn[]?; (.namespace // $namespace) + "/" + .name as $dependency
          | any($reconcilers[]; identity == $dependency)));
      "Flux dependency references an unknown owner")
  | require(all($owners[]; . as $owner
      | if any(.resources[]; has("sops")) then
          any($reconcilers[]; identity == $owner.owner and .spec.decryption.provider == "sops"
              and .spec.decryption.secretRef.name == "sops-age")
        else true end);
      "Encrypted resources require decryption on their own reconciler")
  | require(all($owners[];
      if any(.resources[]; .kind == "ProxyClass") then
        all(.resources[]; .kind != "HelmRelease")
      else true end);
      "Operator installation and ProxyClass must have separate owners")
  | (def visit($id; $seen):
      if ($seen | index($id)) != null then error("Flux dependency cycle: " + $id)
      else $reconcilers[] | select(identity == $id) | .metadata.namespace as $namespace
        | .spec.dependsOn[]? | visit((.namespace // $namespace) + "/" + .name; $seen + [$id])
      end;
      [$reconcilers[] | visit(identity; [])])
  | true
' rendered/owners.json

touch "$out"
