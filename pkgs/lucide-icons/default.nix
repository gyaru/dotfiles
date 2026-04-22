{
  lib,
  stdenvNoCC,
  fetchzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "lucide-icons";
  version = "0.373.0";
  dontConfigure = true;

  src = fetchzip {
    url = "https://github.com/lucide-icons/lucide/releases/download/${version}/lucide-font-${version}.zip";
    sha256 = "sha256-tQDMfPxx3zL0WfsTukELbfovATM8wIk3RuIKgZbqK/o=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype/${pname}
    mv lucide.ttf $out/share/fonts/truetype/${pname}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Community-run fork of Feather Icons";
    homepage = "https://lucide.dev/";
    maintainers = with maintainers; [gyaru];
    platforms = platforms.all;
    license = licenses.ofl;
  };
}
