_: {
  flake.modules.nixos.nix = {
    nix.channel.enable = false;

    nix.settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes" "pipe-operators"];
    };
  };

  flake.modules.nixos.nix-builder = {lib, ...}: let
    inherit (lib.lists) singleton;
  in {
    nix.settings = {
      experimental-features = singleton "cgroups";
      use-cgroups = true;
      max-jobs = "auto";
      cores = 0;
      eval-cache = true;
      system-features = ["big-parallel" "kvm" "nixos-test"];
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
