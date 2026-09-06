{
  lib,
  pkgs,
}: let
  inherit (lib.attrsets) filterAttrs mapAttrs;
  inherit (lib.filesystem) readDir;

  packageDirectories =
    readDir ../packages
    |> filterAttrs (name: type: type == "directory" && (readDir ../packages/${name}) ? "default.nix");
in
  packageDirectories
  |> mapAttrs (name: _: pkgs.callPackage ../packages/${name} {})
