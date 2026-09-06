_: {
  flake.modules.nixos.firewall = {
    networking.firewall = {
      enable = true;
      allowPing = false;
      logReversePathDrops = true;
    };
  };

  flake.modules.nixos.tailscale = {
    services.tailscale.enable = true;
  };
}
