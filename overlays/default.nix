{
  additions = final: prev:
    import ../lib/packages.nix {
      inherit (prev) lib;
      pkgs = final;
    };

  modifications = _: prev: let
    codexVersion = "0.153.4";
    codexSrc = prev.fetchFromGitHub {
      owner = "openai";
      repo = "codex";
      tag = "rust-v${codexVersion}";
      hash = "sha256-lHiDj5SodaM3mh8goMm6esfejeAT+Y3JJWrRnyj6sJo=";
    };
    codexCargoHash = "sha256-GG6kOXmCdq+bZLU2ul0DIVL8lDuweayvZvXn6+bcUZw=";
    xwaylandSatelliteVersion = "0.8.1";
    xwaylandSatelliteSrc = prev.fetchFromGitHub {
      owner = "Supreeeme";
      repo = "xwayland-satellite";
      tag = "v${xwaylandSatelliteVersion}";
      hash = "sha256-BUE41HjLIGPjq3U8VXPjf8asH8GaMI7FYdgrIHKFMXA=";
    };
    xwaylandSatelliteCargoHash = "sha256-16L6gsvze+m7XCJlOA1lsPNELE3D364ef2FTdkh0rVY=";
  in {
    codex = prev.codex.overrideAttrs (_: {
      src = codexSrc;
      version = codexVersion;
      cargoHash = codexCargoHash;
      cargoDeps = prev.rustPlatform.fetchCargoVendor {
        src = codexSrc;
        version = codexVersion;
        pname = "codex";
        sourceRoot = "source/codex-rs";
        hash = codexCargoHash;
      };
    });

    xwayland-satellite = prev.xwayland-satellite.overrideAttrs (_: {
      src = xwaylandSatelliteSrc;
      version = xwaylandSatelliteVersion;
      cargoHash = xwaylandSatelliteCargoHash;
      cargoDeps = prev.rustPlatform.fetchCargoVendor {
        src = xwaylandSatelliteSrc;
        version = xwaylandSatelliteVersion;
        pname = "xwayland-satellite";
        hash = xwaylandSatelliteCargoHash;
      };
    });
  };
}
