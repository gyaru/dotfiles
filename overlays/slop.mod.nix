_: {
  flake.modules.hjem.slop = {
    files.".codex/rules/nix-eval.rules".text =
      /*
      starlark
      */
      ''
        prefix_rule(
            pattern = ["nix", "--accept-flake-config", "eval"],
            decision = "allow",
        )
      '';
  };

  flake.overlays.codex = _: prev: {
    codex = prev.codex.overrideAttrs (finalAttrs: _: {
      version = "0.155.1";
      src = prev.fetchFromGitHub {
        owner = "openai";
        repo = "codex";
        tag = "rust-v${finalAttrs.version}";
        hash = "sha256-iFW66odceRNBsVG5bD9SdcQGxhpm/QIZwYjGCrfMXiI=";
      };
      cargoHash = "sha256-6IAX/SFSSgSKKFxKsUXoZ9nNQaHJ+EjZ5a4bJwyDdF0=";
      cargoDeps = prev.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) src version pname;
        sourceRoot = "source/codex-rs";
        hash = finalAttrs.cargoHash;
      };
    });
  };
}
