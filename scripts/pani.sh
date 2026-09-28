#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf '%s\n' \
        'Usage: pani {switch|boot|test|build|dry-build} [host] [nh options...]' \
        '       pani check [nix flake check options...]' \
        '' \
        'Without a host, build and activate locally.' \
        'With a different host, build locally and activate there over SSH.' \
        'Remote activation automatically detects passwordless sudo.' \
        'Use --build-host HOST to build remotely instead.' \
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
target_host=""
if [[ -n "$host" ]]; then
    args+=(--hostname "$host")
    if [[ "$host" != "$(uname --nodename)" && "$action" != build && "$action" != dry-build ]]; then
        args+=(--target-host "$host")
        target_host="$host"
    fi
fi

elevation="${NH_ELEVATION_STRATEGY:-}"
next_option=""
probe=true
for argument in "$@"; do
    if [[ "$next_option" == target ]]; then
        target_host="$argument"
        next_option=""
        continue
    fi
    case "$argument" in
        --) break ;;
        --target-host) next_option=target ;;
        --target-host=*) target_host="${argument#*=}" ;;
        --elevation-strategy|--elevation-strategy=*|-e|-e?*) elevation=explicit ;;
        --dry|-n|--help|-h) probe=false ;;
    esac
done

if [[ "$action" =~ ^(switch|boot|test)$ && -n "$target_host" && -z "$elevation" && "$probe" == true ]]; then
    if ssh -o BatchMode=yes -o ConnectTimeout=10 "$target_host" \
        'sudo --non-interactive --reset-timestamp true' </dev/null >/dev/null 2>&1; then
        args+=(--elevation-strategy passwordless)
    fi
fi

if [[ "$action" == dry-build ]]; then
    action=build
    args+=(--dry)
fi

exec nh os "$action" . "${args[@]}" "$@"
