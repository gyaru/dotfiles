{inputs, ...}: {
  flake.overlays.slop = _: prev: let
    agentPkgs = import inputs.llm-agents.inputs.nixpkgs {
      inherit (prev.stdenv.hostPlatform) system;
      config.allowUnfreePredicate = package: prev.lib.getName package == "claude-code";
      overlays = [inputs.llm-agents.overlays.shared-nixpkgs];
    };
  in {
    inherit (agentPkgs.llm-agents) codex claude-code opencode;

    t3code = agentPkgs.llm-agents.t3code.overrideAttrs (oldAttrs: {
      postFixup =
        (oldAttrs.postFixup or "")
        +
        /*
        bash
        */
        ''
          for program in "$out/bin/t3" "$desktop/bin/t3code-desktop"; do
            wrapProgram "$program" \
              --inherit-argv0 \
              --set T3CODE_TELEMETRY_ENABLED false \
              --set T3CODE_OTEL_SDK_DISABLED true
          done
        '';
    });
  };
}
