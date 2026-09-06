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

Build or inspect another host:

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

`pani <command> [host]` wraps common `nixos-rebuild` operations:

| Command | Purpose |
| --- | --- |
| `switch` | Build and activate the configuration |
| `boot` | Build and select the configuration for next boot |
| `test` | Activate without changing the bootloader |
| `build` | Build without activation |
| `dry-build` | Show what would be built |
| `check` | Run flake checks |

The host defaults to the current machine's hostname.
Run from the repository, or set `PANI_FLAKE` to its path. Builds run as the
current user; activation requires sudo.

```bash
nixos-rebuild switch \
  --flake path:.#lapi \
  --build-host lis@lapi \
  --target-host lis@lapi \
  --elevate sudo \
  --ask-elevate-password \
  --accept-flake-config
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
│   │   ├── vm.nix
│   │   └── zfs.nix
│   └── radiata/
│       ├── users/           # Host-specific hjem users
│       └── configuration.nix
├── k3s/
│   └── cluster/             # Kubernetes resources
├── lib/                     # Shared constructors and entity data
├── modules/
│   ├── hjem/                # Reusable hjem modules
│   └── nixos/               # Reusable NixOS modules
├── overlays/                # Nixpkgs overlays
├── packages/                # Custom packages
├── scripts/                 # Development helpers
├── flake.nix
└── secrets.nix              # Agenix recipient declarations
```

## Automatic Discovery

The flake recursively imports every `*.mod.nix` file. Registry modules then
derive outputs from directory contents:

- `hosts/<name>/configuration.nix` becomes `nixosConfigurations.<name>`.
- `modules/nixos/<name>.nix` becomes `nixosModules.<name>`.
- `modules/hjem/<name>.nix` becomes `hjemModules.<name>`.
- `packages/<name>/default.nix` becomes `packages.<system>.<name>` and is added
  to the local package overlay. Package outputs exclude unsupported platforms.
- Standalone concerns can define their outputs directly in a `*.mod.nix` file,
  such as `packages/niri-pick-color.mod.nix`.

Adding or removing a host, module, or package therefore does not require
editing a central declaration list.
