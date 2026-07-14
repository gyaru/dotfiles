{
  fetchzip,
  lib,
  stdenvNoCC,
}: let
  pname = "balsamiqsans";
  version = "1.020";
in
  stdenvNoCC.mkDerivation {
    inherit pname version;
    dontConfigure = true;

    src = fetchzip {
      url = "https://github.com/balsamiq/balsamiqsans/releases/download/${version}/balsamiqsans-fonts.zip";
      sha256 = "fP4jdMGftsRhkW109qC7IGy/zI9Vtzmw9jSSUJ2eTKw=";
    };

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/fonts/{truetype,opentype}/${pname}
      mv fonts/ttf/* $out/share/fonts/truetype/${pname}
      mv fonts/otf/* $out/share/fonts/opentype/${pname}

      runHook postInstall
    '';

    meta = with lib; {
      description = "The Balsamiq Sans Font";
      homepage = "https://balsamiq.com/givingback/opensource/font/";
      maintainers = with maintainers; [gyaru];
      platforms = platforms.all;
      license = licenses.ofl;
    };
  }
