_: {
  flake.overlays.xwayland-satellite = _: prev: {
    xwayland-satellite = prev.xwayland-satellite.overrideAttrs (finalAttrs: _: {
      version = "0.8.1";
      src = prev.fetchFromGitHub {
        owner = "Supreeeme";
        repo = "xwayland-satellite";
        tag = "v${finalAttrs.version}";
        hash = "sha256-BUE41HjLIGPjq3U8VXPjf8asH8GaMI7FYdgrIHKFMXA=";
      };
      cargoHash = "sha256-16L6gsvze+m7XCJlOA1lsPNELE3D364ef2FTdkh0rVY=";
      cargoDeps = prev.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) src version pname;
        hash = finalAttrs.cargoHash;
      };
    });
  };
}
