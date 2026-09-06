#!/usr/bin/env bash
set -euo pipefail

(( $# == 2 )) || { printf 'Usage: render-cluster.sh K3S_DIRECTORY OUTPUT_DIRECTORY\n' >&2; exit 1; }
cluster_root="$(realpath "$1/cluster")"
mkdir --parents "$2"
output_dir="$(realpath "$2")"
declare -A visited=()
owners=(flux-system/flux-system)
paths=(./k3s/cluster)
printf '[]\n' > "$output_dir/owners.json"

for (( index=0; index < ${#owners[@]}; index++ )); do
    owner="${owners[index]}"
    path="${paths[index]}"
    if [[ -v "visited[$owner]" ]]; then
        [[ "${visited[$owner]}" == "$path" ]] || { printf 'Conflicting paths for %s\n' "$owner" >&2; exit 1; }
        continue
    fi
    visited["$owner"]="$path"
    [[ "$path" == ./k3s/cluster || "$path" == ./k3s/cluster/* ]] || { printf 'Unsupported Flux path: %s\n' "$path" >&2; exit 1; }
    directory="$(realpath "$cluster_root/${path#./k3s/cluster}")"
    [[ "$directory" == "$cluster_root" || "$directory" == "$cluster_root/"* ]] || { printf 'Flux path escapes cluster: %s\n' "$path" >&2; exit 1; }

    kustomize build "$directory" > "$output_dir/resources.yaml"
    yq --output-format=json --indent=0 '.' "$output_dir/resources.yaml" | jq --slurp '.' > "$output_dir/resources.json"
    jq --arg owner "$owner" --arg path "$path" --slurpfile resources "$output_dir/resources.json" \
        '. + [{owner: $owner, path: $path, resources: $resources[0]}]' \
        "$output_dir/owners.json" > "$output_dir/owners.next.json"
    mv "$output_dir/owners.next.json" "$output_dir/owners.json"

    while IFS=$'\t' read -r child_owner child_path; do
        owners+=("$child_owner")
        paths+=("$child_path")
    done < <(jq --raw-output '.[] | select(.apiVersion == "kustomize.toolkit.fluxcd.io/v1" and .kind == "Kustomization")
        | [(.metadata.namespace + "/" + .metadata.name), .spec.path] | @tsv' "$output_dir/resources.json")
done

jq '[.[].resources[]]' "$output_dir/owners.json" > "$output_dir/cluster.json"
