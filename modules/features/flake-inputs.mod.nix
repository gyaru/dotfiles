{
  self,
  lib,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.lists) map;
  inherit (lib.trivial) genericClosure;

  inputNode = input: {
    key = "${input}";
    inherit input;
  };
in {
  flake.modules.nixos.flake-inputs = {
    system.extraDependencies =
      map ({key, ...}: key)
      <| genericClosure {
        startSet = map inputNode <| attrValues self.inputs;
        operator = {input, ...}: map inputNode <| attrValues (input.inputs or {});
      };
  };
}
