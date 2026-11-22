_: {
  flake.overlays.antigravity-acp = _: prev: {
    antigravity-acp = prev.antigravity-acp.overrideAttrs (finalAttrs: _: let
      sources = {
        x86_64-linux = {
          url = "https://dl.google.com/agy-extensions/releases/linux/agy-acp-server-${finalAttrs.version}-linux-x86_64.zip";
          hash = "sha256-md2GEkUIBQEWGde4RHzjdMKJ4AVJ2FV/NnkOHdYlaFI=";
        };
        aarch64-linux = {
          url = "https://dl.google.com/agy-extensions/releases/linux/agy-acp-server-${finalAttrs.version}-linux-arm64.zip";
          hash = "sha256-5yngXvVO8HY+SJAAMkZrR/p8mTnN4lf5O6SUEKtXess=";
        };
        aarch64-darwin = {
          url = "https://dl.google.com/agy-extensions/releases/macos/agy-acp-server-${finalAttrs.version}-darwin-arm64.zip";
          hash = "sha256-EjoW1cQKismeIPAaYraN2GD9lrHFKN+46qN8qHM9SEU=";
        };
      };
    in {
      version = "1.5.2";
      src = prev.fetchurl sources.${prev.stdenv.hostPlatform.system};
    });
  };
}
