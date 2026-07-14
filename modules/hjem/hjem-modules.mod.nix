{lib, ...}: let
  inherit (lib.attrsets) filterAttrs mapAttrs' nameValuePair;
  inherit (lib.filesystem) readDir;
  inherit (lib.strings) hasSuffix removeSuffix;

  moduleFiles =
    readDir ./.
    |> filterAttrs (
      name: type: type == "regular" && hasSuffix ".nix" name && !hasSuffix ".mod.nix" name
    );
in {
  flake.hjemModules =
    moduleFiles
    |> mapAttrs' (
      name: _: nameValuePair (removeSuffix ".nix" name) ./${name}
    );
}
