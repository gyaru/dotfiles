{inputs, ...}: {
  flake.overlays.slop = _: prev: let
    agentPkgs = import inputs.llm-agents.inputs.nixpkgs {
      inherit (prev.stdenv.hostPlatform) system;
      config.allowUnfreePredicate = package: prev.lib.getName package == "claude-code";
      overlays = [inputs.llm-agents.overlays.shared-nixpkgs];
    };
  in {
    inherit (agentPkgs.llm-agents) codex claude-code opencode t3code;
  };
}
