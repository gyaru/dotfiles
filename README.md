<div align="center">
  <img src="https://github.com/gyaru/gyaru/raw/main/lis.png" width="150px" alt="hi">
</div>

# lis' dotfiles

Personal NixOS configurations built with flake-parts and the dendritic pattern.

## Hosts

- **lapi**: home server configuration
- **radiata**: AMD/Niri desktop with hjem
- **hana**: raspberry pi 4
- **gon**: MediaMTX server

## Usage

Enter the development shell:

```bash
nix develop
```

On a fresh machine where `pipe-operators` is not enabled globally yet, accept
the repository setting for the first evaluation:

```bash
nix --accept-flake-config develop
```

After activating a host configuration, ordinary Nix commands work without
that flag.

Rebuild the current host:

```bash
pani switch
```

Build Lapi's configuration locally, then switch Lapi over Tailscale:

```bash
pani switch lapi
```

Build another host's configuration locally without activating:

```bash
pani build lapi
nix build .#nixosConfigurations.lapi.config.system.build.toplevel
```

Run all checks:

```bash
pani check
```

Evaluate every host and both Linux architectures without building them:

```bash
nix flake check --all-systems --no-build
```

The checks include Nix formatting/linting, ShellCheck, and a rendered cluster
check for image digests, storage retention, single-writer rollouts, node
placement, and PVC references, plus offline Kubernetes and Flux schema validation.

## Pani

`pani <command> [host] [nh options...]` supplies repository and host defaults
to [nh](https://github.com/nix-community/nh).

| Command | Purpose |
| --- | --- |
| `switch` | Build, activate, and select the configuration for next boot |
| `boot` | Build and select the configuration for next boot |
| `test` | Activate without changing the bootloader |
| `build` | Build without activation |
| `dry-build` | Preview NH's build actions with `nh os build --dry` |
| `check` | Run `nix flake check`, forwarding its options |

Builds run locally by default. The host selects `nixosConfigurations.<host>`;
for `switch`, `boot`, and `test`, a different host also becomes the SSH target.
With no host, or with the local hostname, activation is local too.
`build` and `dry-build` only select the configuration and never activate it.

Run from anywhere inside the repository, or set `PANI_FLAKE` to its path.
Run Pani as your user; NH handles elevation when needed. Pani is available in
the devshell and through `nix run .#pani -- <command>`.

```bash
pani switch lapi --ask
pani check --all-systems --no-build
```

To build remotely as well, pass NH's `--build-host` option:

```bash
pani switch lapi --build-host lapi
```

## Structure

```text
.
├── hosts/
│   ├── hosts.mod.nix        # Discovers host configuration.nix files
│   ├── lapi/
│   │   ├── services/        # Host services
│   │   ├── configuration.nix
│   │   ├── gaming.nix
│   │   └── zfs.nix
│   └── radiata/
│       ├── users/           # Host-specific hjem users
│       └── configuration.nix
├── k3s/
│   └── cluster/             # Kubernetes resources
├── lib/                     # Shared constructors and entity data
├── modules/
│   ├── features/            # Named NixOS and hjem features (*.mod.nix)
│   ├── profiles.mod.nix     # Feature bundles, such as workstation
│   ├── module-classes.mod.nix # flake-parts module classes
│   └── entities.mod.nix     # Typed people and machine metadata
├── overlays/                # Nixpkgs overlays
├── packages/                # Custom packages, including pani.mod.nix
├── scripts/                 # Development helpers
├── flake.nix
└── secrets.nix              # Agenix recipient declarations
```
