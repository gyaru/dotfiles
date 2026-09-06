_: {
  perSystem = {pkgs, ...}: {
    packages.niri-pick-color = pkgs.callPackage ({
      lib,
      niri,
      wl-clipboard,
      writeShellApplication,
    }: let
      inherit (lib.meta) getExe getExe';
    in
      writeShellApplication {
        name = "niri-pick-color";
        text =
          /*
          bash
          */
          ''
            color="$(${getExe niri} msg pick-color)"
            printf %s "$color" | ${getExe' wl-clipboard "wl-copy"}
          '';
      }) {};
  };
}
