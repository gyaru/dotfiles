{self, ...}: {
  flake.modules.nixos.workstation = {
    imports = with self.modules.nixos; [
      audio
      base
      desktop
      bluetooth
      file-manager
      network-tuning
      flatpak
      gaming
      security
      kernel-hardening
      wayland
      nix-builder
      home
      shell
      fonts
      desktop-locale
      stockholm-time
      firewall
      tailscale
      nix-index
      onepassword
    ];
  };

  flake.modules.hjem.workstation = {
    imports = with self.modules.hjem; [
      home
      browser
      xdg-user-dirs
      development
      slop
      shell
      desktop-apps
      obsidian
      onepassword
      git
      kitty
      niri
      noctalia
    ];
  };
}
