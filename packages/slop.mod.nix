{
  inputs,
  lib,
  self,
  ...
}: let
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe;
  inherit (lib.attrsets) optionalAttrs;
in {
  perSystem = {
    config,
    pkgs,
    ...
  }: let
    agentPkgs = import inputs.nixpkgs {
      inherit (pkgs.stdenv.hostPlatform) system;
      config.allowUnfreePredicate = package: lib.getName package == "claude-code";
      overlays = singleton self.overlays.slop;
    };

    spdxLicenses = pkgs.fetchFromGitHub {
      owner = "spdx";
      repo = "license-list-data";
      rev = "c4a7237ec8f4654e867546f9f409749300f1bf4c";
      hash = "sha256-FbeeEBAg9ih6DkAsXdU6ruZwkC7A2u2zYBvblpl54q0=";
    };
  in {
    packages.slop = pkgs.callPackage ({server ? false}:
      (pkgs.t3code.override {
        enableCodex = true;
        enableClaude = true;
        enableOpencode = true;
        inherit (agentPkgs) codex claude-code opencode;

        t3code-unwrapped = pkgs.t3code.unwrapped.overrideAttrs (finalAttrs: previousAttrs:
          {
            version = "0.0.45";

            src = pkgs.fetchFromGitHub {
              owner = "pingdotgg";
              repo = "t3code";
              tag = "v${finalAttrs.version}";
              hash = "sha256-8drTHjFqa2vJ96jhpRZXmNbtbXtKk1q40jOEp9dohNc=";
            };

            pnpmDeps = previousAttrs.pnpmDeps.overrideAttrs {
              inherit (finalAttrs) version src;
              outputHash = "sha256-2dGEHOQrnidTei54NlZTJh5u5/i810hb2LddK4XfUNQ=";
            };

            postPatch =
              previousAttrs.postPatch
              +
              /*
              bash
              */
              ''
                mkdir --parents .generated/third-party-licenses/spdx
                cp --recursive ${spdxLicenses}/json/details .generated/third-party-licenses/spdx/v3.28.0
              '';

            postFixup =
              (previousAttrs.postFixup or "")
              +
              /*
              bash
              */
              ''
                ${getExe pkgs.patchelf} --add-rpath ${pkgs.stdenv.cc.cc.lib}/lib \
                  "$out/libexec/t3code/apps/server/node_modules/node-pty/prebuilds/linux-${pkgs.stdenv.hostPlatform.node.arch}/pty.node"
              '';
          }
          // optionalAttrs server {
            pname = "t3code-server";
            desktopItems = [];
            dontPnpmBuild = true;

            buildPhase =
              /*
              bash
              */
              ''
                runHook preBuild
                pnpm vp run --filter t3 build
                runHook postBuild
              '';

            installPhase =
              /*
              bash
              */
              ''
                runHook preInstall
                mkdir --parents "$out/libexec/t3code/apps/server"
                cp --recursive --no-preserve=mode node_modules "$out/libexec/t3code"
                cp --recursive --no-preserve=mode apps/server/{node_modules,dist} "$out/libexec/t3code/apps/server"
                find "$out/libexec/t3code" -xtype l -delete
                makeWrapper ${getExe pkgs.nodejs} "$out/bin/t3" \
                  --add-flags "$out/libexec/t3code/apps/server/dist/bin.mjs"
                runHook postInstall
              '';

            meta = previousAttrs.meta // {mainProgram = "t3";};
          });
      }).overrideAttrs (previousAttrs: {
        pname =
          if server
          then "slop-server"
          else "slop";
        paths = previousAttrs.paths ++ [agentPkgs.codex agentPkgs.claude-code agentPkgs.opencode];
      })) {};

    packages.slop-server = config.packages.slop.override {server = true;};
  };
}
