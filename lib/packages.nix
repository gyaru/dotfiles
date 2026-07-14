{
  lib,
  pkgs,
}: let
  inherit (lib.attrsets) filterAttrs mapAttrs;
  inherit (lib.filesystem) readDir;

  packageDirectories =
    readDir ../packages
    |> filterAttrs (_: type: type == "directory");
in
  packageDirectories
  |> mapAttrs (name: _: pkgs.callPackage ../packages/${name} {})
