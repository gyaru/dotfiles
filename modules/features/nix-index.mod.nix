{inputs, ...}: {
  flake.modules.nixos.nix-index = {lib, ...}: let
    inherit (lib.lists) singleton;
  in {
    imports = singleton inputs.nix-index-database.nixosModules.nix-index;

    programs.nix-index-database.comma.enable = true;
  };
}
