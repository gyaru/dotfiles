<div align="center">
	<img src="https://github.com/gyaru/gyaru/raw/main/lis.png" width="150px" alt="hi">
</div>

# lis' nix config

modular nixos & home-manager configuration with impermanence

**personal use**

## hosts
- **radiata** - desktop (hyprland, amd)
- **carrot** - macbook (nix-darwin)
- **lapi** - server

## quick start
```bash
nix develop
pani switch  # rebuild current host
```

## pani commands
- `pani switch` - rebuild & switch
- `pani test` - test config without bootloader
- `pani check` - validate flake
- `pani impermanence` - check what dies on reboot

## structure
```
├── flake.nix        # entrypoint
├── hosts/           # machine-specific
├── home/            # user configs
├── modules/         # reusable nixos modules
├── pkgs/            # custom packages
└── scripts/         # helpers (pani)
```

## modules
- **audio** - pipewire w/ device config
- **wayland** - compositor agnostic portal setup
- **impermanence** - btrfs rollback on boot
- **desktop** - kernel tweaks & base desktop stuff
- **gaming** - steam, gamemode, etc
