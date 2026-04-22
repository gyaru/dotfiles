{
  appimageTools,
  fetchurl,
  makeDesktopItem,
  symlinkJoin,
  stdenv,
}: let
  pname = "curseforge";
  version = "1.0.0";
  src = fetchurl {
    url = "https://curseforge.overwolf.com/downloads/curseforge-latest-linux.AppImage";
    hash = "sha256-RXW5eFCqHzuM4I+gGjUyyLoQTrp9l6aShIfx/fLiGEU=";
  };
  extracted = appimageTools.extractType2 {inherit pname version src;};
  appimage = appimageTools.wrapType2 {inherit pname version src;};
  icon = stdenv.mkDerivation {
    name = "${pname}-icon";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/icons/hicolor/256x256/apps
      cp ${extracted}/.DirIcon $out/share/icons/hicolor/256x256/apps/${pname}.png
    '';
  };
  desktopItem = makeDesktopItem {
    name = pname;
    exec = pname;
    icon = pname;
    desktopName = "CurseForge";
    comment = "CurseForge mod manager";
    categories = ["Game"];
  };
in
  symlinkJoin {
    name = pname;
    paths = [appimage desktopItem icon];
  }
