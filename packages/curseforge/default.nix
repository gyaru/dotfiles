{
  appimageTools,
  fetchurl,
  lib,
  makeDesktopItem,
  stdenv,
  symlinkJoin,
}: let
  inherit (lib.lists) singleton;
  pname = "curseforge";
  version = "1.0.0";
  src = fetchurl {
    url = "https://curseforge.overwolf.com/downloads/curseforge-latest-linux.AppImage";
    hash = "sha256-kNkpPMX13RRwGz/lMxocSUZAJ5o1QRLff1SUFbUEbY8=";
  };
  extracted = appimageTools.extract {inherit pname version src;};
  appimage = appimageTools.wrapType2 {inherit pname version src;};
  icon = stdenv.mkDerivation {
    name = "${pname}-icon";
    dontUnpack = true;
    installPhase =
      /*
      bash
      */
      ''
        mkdir --parents $out/share/icons/hicolor/256x256/apps
        cp ${extracted}/.DirIcon $out/share/icons/hicolor/256x256/apps/${pname}.png
      '';
  };
  desktopItem = makeDesktopItem {
    name = pname;
    exec = pname;
    icon = pname;
    desktopName = "CurseForge";
    comment = "CurseForge mod manager";
    categories = singleton "Game";
  };
in
  symlinkJoin {
    name = pname;
    paths = [
      appimage
      desktopItem
      icon
    ];

    meta.platforms = singleton "x86_64-linux";
  }
