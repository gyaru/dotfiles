{lib, ...}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.strings) removeSuffix;
in {
  flake.overlays.proton-ge = _: prev: {
    proton-ge-bin = prev.proton-ge-bin.overrideAttrs (finalAttrs: oldAttrs: {
      version = "GE-Proton11-7";
      steamDisplayName = finalAttrs.version;
      inherit (finalAttrs.passthru.variants.${prev.stdenv.hostPlatform.system}) src toolName;
      passthru =
        oldAttrs.passthru
        // {
          variants =
            mapAttrs (system: hash: let
              toolName = "${finalAttrs.version}-${removeSuffix "-linux" system}";
            in {
              inherit toolName;
              src = prev.fetchzip {
                url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${finalAttrs.version}/${toolName}.tar.gz";
                inherit hash;
              };
            }) {
              x86_64-linux = "sha256-ftW0vE45v2JsbaYqo/So0ZFfvdtakHX0XEXEE4TdxLk=";
              aarch64-linux = "sha256-tyI95zCUQklRVA9YtarD+gBQouMVcJmv7BafNx5CQu8=";
            };
        };
    });
  };
}
