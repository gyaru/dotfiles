{
  inputs,
  lib,
  ...
}: let
  inherit (lib.lists) singleton;
in {
  flake.modules.nixos.gaming = {pkgs, ...}: {
    imports = singleton inputs.nix-gaming.nixosModules.pipewireLowLatency;

    services.pipewire.lowLatency.enable = true;

    programs = {
      gamemode.enable = true;
      steam = {
        enable = true;
        gamescopeSession.enable = true;
        extraCompatPackages = singleton pkgs.proton-ge-bin;
      };
    };
  };
}
