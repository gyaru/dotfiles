#!/usr/bin/env bash
set -euo pipefail
: "${src:?Nix must supply k3s manifests}" "${scripts:?Nix must supply migration scripts}"
: "${out:?Nix must supply a check output}"

work_dir="$(mktemp --directory)"
trap 'rm --recursive --force "$work_dir"' EXIT
mkdir --parents "$work_dir/repo/scripts" "$work_dir/bin"
cp --recursive "$src" "$work_dir/repo/k3s"
chmod --recursive u+w "$work_dir/repo"
cp "$scripts/"*.sh "$work_dir/repo/scripts/"
cd "$work_dir/repo"
git init --quiet --initial-branch=main
git add .
git -c user.name=Test -c user.email=test@example.invalid commit --quiet --message=fixture
revision="$(git rev-parse HEAD)"
bash scripts/render-cluster.sh k3s "$work_dir/rendered"

jq --arg revision "$revision" '{items: map({
  metadata: {namespace: (.owner | split("/")[0]), name: (.owner | split("/")[1]), generation: 2},
  spec: {path: .path, sourceRef: {name: "flux-system"}, prune: false, suspend: false},
  status: {
    lastAppliedRevision: ("main@sha1:" + $revision), observedGeneration: 2,
    conditions: [{type: "Ready", status: "True"}],
    inventory: {entries: [.resources[] | {
      id: ([(.metadata.namespace // ""), .metadata.name,
        (.apiVersion | split("/") | if length == 1 then "" else .[0] end), .kind] | join("_"))
    }]}
  }
})}' "$work_dir/rendered/owners.json" > "$work_dir/live.json"

cat > "$work_dir/bin/kubectl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == --context=test && "$2" == --namespace=flux-system ]]
shift 2
printf '%s\n' "$*" >> "$TEST_CALLS"
case "$1" in
    get)
        if [[ "$2" == kustomizations.kustomize.toolkit.fluxcd.io ]]; then
            cat "$TEST_LIVE"
        else
            jq '.items[] | select(.metadata.name == "flux-system")' "$TEST_LIVE"
        fi
        ;;
    patch)
        jq '.items |= map(if .metadata.name == "flux-system" then .spec.prune = false | .spec.suspend = true else . end)' "$TEST_LIVE" > "$TEST_LIVE.next"
        mv "$TEST_LIVE.next" "$TEST_LIVE"
        ;;
    *) exit 1 ;;
esac
MOCK
cat > "$work_dir/bin/flux" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
[[ "$*" == '--context=test --namespace=flux-system suspend kustomization flux-system' ]]
printf '%s\n' "$*" >> "$TEST_CALLS"
jq '.items |= map(if .metadata.name == "flux-system" then .spec.suspend = true else . end)' "$TEST_LIVE" > "$TEST_LIVE.next"
mv "$TEST_LIVE.next" "$TEST_LIVE"
MOCK
chmod +x "$work_dir/bin/kubectl" "$work_dir/bin/flux"
patchShebangs "$work_dir/bin"
export PATH="$work_dir/bin:$PATH"
export TEST_LIVE="$work_dir/live.json" TEST_CALLS="$work_dir/calls"

verify() { bash scripts/migrate-flux-ownership.sh verify --context test --revision "$revision"; }
verify
cp "$TEST_LIVE" "$work_dir/valid.json"
for mutation in \
    '.items[1].status.inventory.entries |= .[1:]' \
    '.items[0].status.inventory.entries += [{id: "default_stale__Service"}]' \
    '.items[1].status.observedGeneration = 1' \
    '.items[1].status.lastAppliedRevision = "main@sha1:0000000000000000000000000000000000000000"' \
    '.items[1].status.conditions[0].status = "False"' \
    '.items[1].spec.suspend = true' \
    '.items |= .[1:]'; do
    jq "$mutation" "$work_dir/valid.json" > "$TEST_LIVE"
    if verify; then
        printf 'Migration verifier accepted invalid state: %s\n' "$mutation" >&2
        exit 1
    fi
done

cp "$work_dir/valid.json" "$TEST_LIVE"
printf '# dirty\n' >> k3s/cluster/kustomization.yaml
if verify; then
    printf 'Migration verifier accepted dirty manifests\n' >&2
    exit 1
fi
git restore k3s/cluster/kustomization.yaml

if bash scripts/migrate-flux-ownership.sh prepare; then
    printf 'Migration preparation accepted an implicit context\n' >&2
    exit 1
fi
jq '.items[0].spec.prune = true' "$work_dir/valid.json" > "$TEST_LIVE"
bash scripts/migrate-flux-ownership.sh prepare --context test
jq --exit-status '.items[0].spec | .prune == false and .suspend == true' "$TEST_LIVE"
printf 'Migration helper accepted valid state and rejected seven invalid inventories plus dirty manifests.\n'
touch "$out"
