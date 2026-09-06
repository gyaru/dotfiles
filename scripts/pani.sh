#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf '%s\n' \
        'Usage: pani {switch|boot|test|build|dry-build} [host] [nh options...]' \
        '       pani check [nix flake check options...]' \
        '' \
        'Without a host, build and activate locally.' \
        'With a different host, build and activate there over SSH.' \
        'Build actions never activate a configuration.'
}

action="${1:-}"
case "$action" in
    --help) usage; exit 0 ;;
    switch|boot|test|build|dry-build|check) shift ;;
    *) usage >&2; exit 1 ;;
esac

flake_dir="${PANI_FLAKE:-}"
if [[ -z "$flake_dir" ]]; then
    flake_dir="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
if [[ ! -f "$flake_dir/flake.nix" ]]; then
    printf 'No flake.nix in %s; set PANI_FLAKE to the repository.\n' "$flake_dir" >&2
    exit 1
fi

cd "$flake_dir"
if [[ "$action" == check ]]; then
    exec nix flake check . "$@"
fi

host=""
if [[ $# -gt 0 && "$1" != -* ]]; then
    host="$1"
    shift
fi

args=()
if [[ -n "$host" ]]; then
    args+=(--hostname "$host")
    if [[ "$host" != "$(uname --nodename)" ]]; then
        args+=(--build-host "$host" --target-host "$host")
    fi
fi

if [[ "$action" == dry-build ]]; then
    action=build
    args+=(--dry)
fi

exec nh os "$action" . "${args[@]}" "$@"
