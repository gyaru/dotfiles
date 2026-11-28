{
  description = "lis' nix flakes";

  nixConfig.extra-experimental-features = ["pipe-operators"];

  outputs = {self, ...}: let
    pins = import ./.tack;
    inherit (pins.nixpkgs.lib.attrsets) removeAttrs;
    inherit (pins.nixpkgs.lib.filesystem) listFilesRecursive;
    inherit (pins.nixpkgs.lib.lists) filter;
    inherit (pins.nixpkgs.lib.strings) hasSuffix;

    inputs = removeAttrs pins ["__functor" "_meta" "_patched"];
  in
    inputs.flake-parts.lib.mkFlake {
      inputs = inputs // {self = self // {inherit inputs;};};
    } {
      imports = filter (hasSuffix ".mod.nix") (listFilesRecursive ./.);
    };
}
