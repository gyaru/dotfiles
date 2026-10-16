{
  inputs,
  lib,
  self,
  ...
}: {
  perSystem = {pkgs, ...}: let
    agentPkgs = import inputs.nixpkgs {
      inherit (pkgs.stdenv.hostPlatform) system;
      config.allowUnfreePredicate = package: lib.getName package == "claude-code";
      overlays = [self.overlays.slop];
    };
    providers = with agentPkgs; [codex claude-code opencode];
    t3code = agentPkgs.t3code.override {providerPackages = providers;};
    mkSlop = server:
      pkgs.symlinkJoin {
        name = "slop${lib.optionalString server "-server"}-${t3code.version}";
        inherit (t3code) version;
        paths = [t3code] ++ lib.optional (!server) t3code.desktop ++ providers;
        meta = t3code.meta // {mainProgram = "t3";};
      };
  in {
    packages.slop = mkSlop false;
    packages.slop-server = mkSlop true;
  };
}
