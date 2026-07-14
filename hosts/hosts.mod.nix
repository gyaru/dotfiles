{
  inputs,
  lib,
  self,
  ...
}: let
  inherit (lib.attrsets) filterAttrs mapAttrs;
  inherit (lib.filesystem) readDir;

  nixosSystem = import ../lib/nixos-system.nix {inherit inputs self;};
  hostDirectories =
    readDir ./.
    |> filterAttrs (
      name: type: type == "directory" && (readDir ./${name}) ? "configuration.nix"
    );
in {
  flake.nixosConfigurations =
    hostDirectories
    |> mapAttrs (
      hostName: _:
        nixosSystem {
          inherit hostName;
          module = ./${hostName}/configuration.nix;
        }
    );
}
