_: {
  flake.modules.hjem.browser = {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.lists) singleton;
    inherit (lib.meta) getExe;
  in {
    environment.sessionVariables = {
      BROWSER = getExe pkgs.firefox-bin;
      MOZ_USE_XINPUT2 = "1";
    };

    packages = singleton pkgs.firefox-bin;
  };
}
