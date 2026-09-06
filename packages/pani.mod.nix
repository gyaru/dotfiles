_: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.strings) fileContents;
  in {
    packages.pani = pkgs.writeShellApplication {
      name = "pani";
      runtimeInputs = with pkgs; [coreutils git nh nix];
      text = fileContents ../scripts/pani.sh;
    };
  };
}
