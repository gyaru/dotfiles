<div align="center">
  <img src="https://github.com/gyaru/gyaru/raw/main/lis.png" width="150px" alt="hi">
</div>

# lis' nix config

Personal NixOS configurations built with flake-parts and the dendritic pattern.

## Hosts

- **lapi**: home server running K3s, ZFS and Samba.
- **radiata**: AMD/Hyprland desktop and hjem configuration.

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

After activating either host configuration, ordinary Nix commands work without
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
| `impermanence` | Show files that would be lost after reboot |

The host defaults to the current machine's hostname.

## Structure

```text
.
├── cluster/                 # Kubernetes resources, deployed manually
├── hosts/
│   ├── hosts.mod.nix        # Discovers host configuration.nix files
│   ├── lapi/
│   │   ├── services/        # K3s and Samba
│   │   ├── configuration.nix
│   │   ├── gaming.nix
│   │   ├── vm.nix
│   │   └── zfs.nix
│   └── radiata/
│       ├── users/           # Host-specific hjem users
│       └── configuration.nix
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
  to the local package overlay.

Adding or removing a host, module, or package therefore does not require
editing a central declaration list.
