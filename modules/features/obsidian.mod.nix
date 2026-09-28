_: {
  flake.modules.hjem.obsidian = {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.lists) singleton;
  in {
    packages = singleton pkgs.obsidian;
  };
}
