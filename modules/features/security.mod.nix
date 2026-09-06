_: {
  flake.modules.nixos.security = _: {
    security = {
      polkit.enable = true;
    };
  };
}
