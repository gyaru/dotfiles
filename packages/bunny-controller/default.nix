{
  ffmpeg-headless,
  lib,
  makeWrapper,
  python3,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "bunny-controller";
  version = "0.1.0";
  src = ./controller.py;

  dontUnpack = true;
  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    install -Dm755 $src $out/libexec/bunny-controller.py
    makeWrapper ${lib.getExe python3} $out/bin/bunny-controller \
      --add-flags $out/libexec/bunny-controller.py \
      --set BUNNY_FFMPEG ${lib.getExe ffmpeg-headless} \
      --set BUNNY_FFPROBE ${lib.getExe' ffmpeg-headless "ffprobe"}
  '';

  meta.mainProgram = "bunny-controller";
}
