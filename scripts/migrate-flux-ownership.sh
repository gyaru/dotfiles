#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf '%s\n' \
        'Usage: migrate-flux-ownership.sh prepare --context CONTEXT' \
        '       migrate-flux-ownership.sh verify --context CONTEXT --revision COMMIT'
}
action="${1:-}"
(( $# )) || { usage >&2; exit 1; }
shift
context='' revision=''
while (( $# )); do
    case "$1" in
        --context) context="${2:?Missing context}"; shift 2 ;;
        --revision) revision="${2:?Missing commit}"; shift 2 ;;
        *) usage >&2; exit 1 ;;
    esac
done
[[ -n "$context" && ( "$action" == prepare || "$action" == verify ) ]] || { usage >&2; exit 1; }
kube=(kubectl --context="$context" --namespace=flux-system)
root_resource=kustomizations.kustomize.toolkit.fluxcd.io/flux-system

if [[ "$action" == prepare ]]; then
    "${kube[@]}" get "$root_resource" --output=json | jq --exit-status \
        '.spec.path == "./k3s/cluster" and .spec.sourceRef.name == "flux-system"' > /dev/null
    flux --context="$context" --namespace=flux-system suspend kustomization flux-system
    # Allow an already-running reconciliation to finish before changing prune.
    deadline=$(( SECONDS + 360 ))
    while true; do
        status="$("${kube[@]}" get "$root_resource" --output=json)"
        if ! jq --exit-status 'any(.status.conditions[]?; .type == "Reconciling" and .status == "True")' <<< "$status" > /dev/null; then
            break
        fi
        (( SECONDS < deadline )) || { printf 'Reconciliation is still active; leave Flux suspended and retry.\n' >&2; exit 1; }
        sleep 2
    done
    "${kube[@]}" patch "$root_resource" --type=merge --patch='{"spec":{"prune":false,"suspend":true}}'
    "${kube[@]}" get "$root_resource" --output=json | jq --exit-status \
        '.spec.suspend == true and .spec.prune == false' > /dev/null
    printf '%s\n' 'Root reconciliation is suspended with pruning disabled. Publish the migration, then follow k3s/README.md.'
    exit
fi

[[ "$revision" =~ ^[[:xdigit:]]{40}$ ]] || { printf 'Supply the full Git commit SHA with --revision.\n' >&2; exit 1; }
repo_root="$(git rev-parse --show-toplevel)"
[[ "$(git rev-parse HEAD)" == "$revision" ]] || { printf 'Check out the exact migration revision before verifying.\n' >&2; exit 1; }
[[ -z "$(git status --porcelain -- k3s/cluster)" ]] || { printf 'Cluster manifests must match the committed revision.\n' >&2; exit 1; }
work_dir="$(mktemp --directory)"
trap 'rm --recursive --force "$work_dir"' EXIT
bash "$repo_root/scripts/render-cluster.sh" "$repo_root/k3s" "$work_dir"
"${kube[@]}" get kustomizations.kustomize.toolkit.fluxcd.io --output=json > "$work_dir/live.json"

jq --exit-status --arg revision "$revision" --slurpfile live "$work_dir/live.json" '
  def inventoryID:
    (.apiVersion | split("/") | if length == 1 then "" else .[0] end) as $group
    | [(.metadata.namespace // ""), .metadata.name, $group, .kind] | join("_");
  all(.[]; . as $expected
    | any($live[0].items[];
        .metadata.namespace + "/" + .metadata.name == $expected.owner
        and .spec.path == $expected.path
        and .spec.suspend != true
        and (.status.lastAppliedRevision | endswith(":" + $revision))
        and .status.observedGeneration == .metadata.generation
        and any(.status.conditions[]?; .type == "Ready" and .status == "True")
        and ([.status.inventory.entries[]?.id] | sort)
            == ([$expected.resources[] | inventoryID] | sort)))
' "$work_dir/owners.json" > /dev/null || {
    printf 'Ownership, readiness, or revision differs. Keep root pruning disabled and inspect Flux status.\n' >&2
    exit 1
}
printf '%s\n' 'All inventories match the committed manifests and all owners are ready at that revision.' \
    'Root pruning can now be restored to true in a separate Git change.'
