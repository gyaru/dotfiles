{
  config,
  lib,
  ...
}: let
  inherit (lib.fixedPoints) composeManyExtensions;
in {
  flake.overlays = {
    additions = final: prev:
      import ../lib/packages.nix {
        inherit (prev) lib;
        pkgs = final;
      };

    modifications = composeManyExtensions [
      config.flake.overlays.proton-ge
      config.flake.overlays.slop
      config.flake.overlays.xwayland-satellite
    ];
  };
}
