{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
}: let
  pname = "mplus-fonts";
  version = "TESTFLIGHT_063a";
in
  stdenvNoCC.mkDerivation {
    inherit pname version;
    dontConfigure = true;

    src = fetchFromGitHub {
      owner = "coz-m";
      repo = "MPLUS_FONTS";
      rev = "336fec4e9e7c1e61bd22b82e6364686121cf3932";
      hash = "sha256-jzDDUs1dKjqNjsMeTA2/4vm+akIisnOuE2mPQS7IDSA=";
    };

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/fonts/{truetype,opentype}/${pname}
      mv fonts/ttf/* $out/share/fonts/truetype/${pname}
      mv fonts/otf/* $out/share/fonts/opentype/${pname}

      runHook postInstall
    '';

    meta = with lib; {
      description = "M+ Fonts";
      homepage = "https://mplusfonts.github.io";
      maintainers = with maintainers; [gyaru];
      platforms = platforms.all;
      license = licenses.ofl;
    };
  }
