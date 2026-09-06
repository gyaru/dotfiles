#!/usr/bin/env bash
set -euo pipefail
: "${src:?}" "${out:?}" "${renderer:?}" "${schemas:?}" "${kubernetesVersion:?}"

[[ "$kubernetesVersion" == 1.35 ]] || { printf 'Update the pinned Kubernetes schemas for %s\n' "$kubernetesVersion" >&2; exit 1; }
bash "$renderer" "$src" rendered
mkdir --parents schemas manifests
cp "$schemas" schemas/_definitions.json

# SCHEMAS FOR NATIVE KUBERNETES RESOURCES
while IFS=$'\t' read -r name definition; do
    jq --null-input --arg definition "$definition" \
        '{"$ref": ("_definitions.json#/definitions/" + $definition)}' > "schemas/$name.json"
done < <(jq --raw-output '.definitions | to_entries[] | .key as $definition
    | .value."x-kubernetes-group-version-kind"[]?
    | [((.kind | ascii_downcase) + "-" + (if .group == "" then "" else (.group | split(".")[0]) + "-" end) + .version), $definition]
    | @tsv' "$schemas")

# CUSTOM RESOURCE SCHEMAS COME FROM THE CHECKED-IN FLUX CRDS
jq --compact-output '.[] | select(.kind == "CustomResourceDefinition") | .spec as $spec
    | .spec.versions[] | select(.served)
    | {name: (($spec.names.kind | ascii_downcase) + "-" + ($spec.group | split(".")[0]) + "-" + .name),
       schema: .schema.openAPIV3Schema}' rendered/cluster.json > custom-schemas.jsonl
while IFS= read -r schema; do
    jq '.schema' <<< "$schema" > "schemas/$(jq --raw-output '.name' <<< "$schema").json"
done < custom-schemas.jsonl

# SOPS METADATA IS REMOVED ONLY FROM THE VALIDATION COPY
jq --compact-output '[.[] | select((.apiVersion | startswith("ENC[")) | not)
    | select(.apiVersion != "tailscale.com/v1alpha1" or .kind != "ProxyClass")
    | if has("sops") and .kind == "Secret" and has("data")
      then .data |= with_entries(.value = "") else . end
    | del(.sops)]
    | to_entries[] | {key, value}' rendered/cluster.json > resources.jsonl
while IFS= read -r resource; do
    jq '.value' <<< "$resource" > "manifests/$(jq --raw-output '.key' <<< "$resource").json"
done < resources.jsonl

kubeconform --strict --summary --schema-location "$PWD/schemas/{{.ResourceKind}}{{.KindSuffix}}.json" manifests

# REGRESSION FIXTURES MUST FAIL VALIDATION
jq 'first(.[] | select(.kind == "Deployment")) | .spec.replicas = "invalid"' rendered/cluster.json > invalid-deployment.json
jq 'first(.[] | select(.apiVersion == "kustomize.toolkit.fluxcd.io/v1" and .kind == "Kustomization"))
    | .spec.interval = 42' rendered/cluster.json > invalid-flux.json
for fixture in invalid-deployment.json invalid-flux.json; do
    if kubeconform --strict --schema-location "$PWD/schemas/{{.ResourceKind}}{{.KindSuffix}}.json" "$fixture" > failure.log 2>&1; then
        printf 'Schema validation accepted %s\n' "$fixture" >&2
        exit 1
    fi
    # A missing schema must not masquerade as a successful negative test.
    grep --quiet 'validation failed' failure.log
done

jq --raw-output '[.[] | select(.apiVersion | startswith("ENC["))] | length
    | "Schema exclusions: \(.) fully encrypted documents; tailscale.com/v1alpha1 ProxyClass is supplied by Helm."' rendered/cluster.json
touch "$out"
