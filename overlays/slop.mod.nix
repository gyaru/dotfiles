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

  flake.overlays.slop = _: prev: {
    codex = prev.codex.overrideAttrs (finalAttrs: _: {
      version = "0.161.0";
      src = prev.fetchFromGitHub {
        owner = "openai";
        repo = "codex";
        tag = "rust-v${finalAttrs.version}";
        hash = "sha256-a6cNz/rKb2L4pFOTBSutNbR7aNyzTI3wF0X7gwidj6g=";
      };
      cargoHash = "sha256-y9TVxrqMQvPUbIhTkfrSCnH/NMp/Liz3rpwSK4AjoMA=";
      cargoDeps = prev.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) src version pname;
        sourceRoot = "source/codex-rs";
        hash = finalAttrs.cargoHash;
      };
    });

    claude-code = prev.claude-code.override {
      manifest = {
        version = "2.1.294";
        platforms = {
          linux-x64 = {
            binary = "claude.zst";
            checksum = "f65567ed6fbf9d4cb670819a9ed00cec415022f93043350b95513a39dbbb0b5f";
          };
          linux-arm64 = {
            binary = "claude.zst";
            checksum = "66c3ea3078271f9c9300f4f2dae3852d1df57aeb0be6cc15183b3eac6cc6a2d3";
          };
        };
      };
    };

    opencode = prev.opencode.overrideAttrs (finalAttrs: previousAttrs: {
      version = "1.18.35";

      src = prev.fetchFromGitHub {
        owner = "anomalyco";
        repo = "opencode";
        tag = "v${finalAttrs.version}";
        hash = "sha256-NM5AbX99hDW+oIojiHSRA+QDz27d8L/v42bwZY+6Imk=";
      };

      passthru =
        previousAttrs.passthru
        // {
          node_modules = previousAttrs.passthru.node_modules.overrideAttrs {
            inherit (finalAttrs) version src;
            outputHash = "sha256-cQLuGI8MBh9l8GisM2k5WXBcZrsdgrNsXUOsYzZVwYY=";
          };
        };
    });
  };
}
