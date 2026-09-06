#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf '%s\n' \
        'Usage: pani {switch|boot|test|build|dry-build|check} [host]' \
        '       pani impermanence [--show-persisted] [--limit COUNT]'
}

flake_dir="${PANI_FLAKE:-}"
if [[ -z "$flake_dir" ]]; then
    flake_dir="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
if [[ ! -f "$flake_dir/flake.nix" ]]; then
    printf 'No flake.nix in %s; set PANI_FLAKE to the repository.\n' "$flake_dir" >&2
    exit 1
fi

check_impermanence() {
    local limit=0 show_persisted=false mount_point
    local -a excludes=(--exclude /nix --exclude /persist --exclude /proc
        --exclude /sys --exclude /dev --exclude /run --exclude /tmp
        --exclude /boot --exclude /efi)
    while (( $# )); do
        case "$1" in
            --show-persisted) show_persisted=true; shift ;;
            --limit)
                [[ "${2:-}" =~ ^[1-9][0-9]*$ ]] || { usage >&2; return 1; }
                limit="$2"; shift 2 ;;
            *) usage >&2; return 1 ;;
        esac
    done

    local mounts
    mounts="$(findmnt --json --list --output TARGET,SOURCE)"
    local -a persisted=()
    while IFS= read -r mount_point; do
        persisted+=("$mount_point")
        excludes+=(--exclude "$mount_point")
    done < <(jq --raw-output '.filesystems[] | select(.source | test("^/persist(/|$)|\\[/persist(/|\\])")) | .target' <<< "$mounts")
    if "$show_persisted"; then
        if (( ${#persisted[@]} )); then
            printf '%s\n' "${persisted[@]}"
        fi
        return
    fi
    printf '%s\n' 'Files on the root filesystem outside detected persistence mounts:' >&2
    sudo fd --one-file-system --base-directory / --type file --hidden --no-ignore \
        "${excludes[@]}" | awk -v limit="$limit" 'limit == 0 || NR <= limit'
}

command="${1:-}"
[[ -n "$command" ]] || { usage >&2; exit 1; }
shift
if [[ "$command" == impermanence ]]; then
    check_impermanence "$@"
    exit
fi
(( $# <= 1 )) || { usage >&2; exit 1; }
host="${1:-$(cat /etc/hostname)}"
cd "$flake_dir"
case "$command" in
    switch|boot|test)
        sudo nixos-rebuild "$command" --flake "$flake_dir#$host" --log-format internal-json |& nom --json
        ;;
    build)
        nix build "$flake_dir#nixosConfigurations.$host.config.system.build.toplevel" --log-format internal-json |& nom --json
        ;;
    dry-build)
        nix build "$flake_dir#nixosConfigurations.$host.config.system.build.toplevel" --dry-run
        ;;
    check) nix flake check ;;
    *) usage >&2; exit 1 ;;
esac
