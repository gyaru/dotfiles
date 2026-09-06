{
  ffmpeg-headless,
  lib,
  makeWrapper,
  python3,
  stdenvNoCC,
  streamlink,
}: let
  inherit (lib.meta) getExe getExe';
in
  stdenvNoCC.mkDerivation {
    pname = "bunny-controller";
    version = "0.1.0";
    src = ./controller.py;

    dontUnpack = true;
    nativeBuildInputs = [makeWrapper];

    installPhase =
      /*
      bash
      */
      ''
        install -D --mode=755 $src $out/libexec/bunny-controller.py
        install -D --mode=644 ${./restream.py} $out/libexec/restream.py
        makeWrapper ${getExe python3} $out/bin/bunny-controller \
          --add-flags $out/libexec/bunny-controller.py \
          --set BUNNY_FFMPEG ${getExe ffmpeg-headless} \
          --set BUNNY_FFPROBE ${getExe' ffmpeg-headless "ffprobe"} \
          --set BUNNY_STREAMLINK ${getExe streamlink}
      '';

    doCheck = true;
    checkPhase =
      /*
      bash
      */
      ''
        PYTHONPATH=${./.} ${getExe python3} ${./test_restream.py}
      '';

    meta.mainProgram = "bunny-controller";
  }
