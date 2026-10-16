{inputs, ...}: {
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

  flake.overlays.slop = _: prev: let
    agentPkgs = import inputs.llm-agents.inputs.nixpkgs {
      inherit (prev.stdenv.hostPlatform) system;
      config.allowUnfreePredicate = package: prev.lib.getName package == "claude-code";
      overlays = [inputs.llm-agents.overlays.shared-nixpkgs];
    };
  in {
    inherit (agentPkgs.llm-agents) codex claude-code opencode;
  };
}
