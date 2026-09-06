{lib, ...}: let
  inherit (lib.attrsets) filterAttrs;
  inherit (lib.meta) availableOn;
in {
  perSystem = {pkgs, ...}: {
    packages = filterAttrs (_: package: availableOn pkgs.stdenv.hostPlatform package) <| import ../lib/packages.nix {inherit lib pkgs;};
  };
}
