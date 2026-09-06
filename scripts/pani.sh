#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf '%s\n' \
        'Usage: pani {switch|boot|test|build|dry-build|check} [host]'
}

flake_dir="${PANI_FLAKE:-}"
if [[ -z "$flake_dir" ]]; then
    flake_dir="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
if [[ ! -f "$flake_dir/flake.nix" ]]; then
    printf 'No flake.nix in %s; set PANI_FLAKE to the repository.\n' "$flake_dir" >&2
    exit 1
fi

command="${1:-}"
[[ -n "$command" ]] || { usage >&2; exit 1; }
shift
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
