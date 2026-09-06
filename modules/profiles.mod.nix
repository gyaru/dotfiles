{self, ...}: {
  flake.modules.nixos.workstation = {
    imports = with self.modules.nixos; [
      audio
      base
      desktop
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
      development
      shell
      desktop-apps
      onepassword
      git
      kitty
      niri
      noctalia
    ];
  };
}
