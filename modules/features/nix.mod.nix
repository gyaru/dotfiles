_: {
  flake.modules.nixos.nix = {
    programs.nh.enable = true;

    nix.channel.enable = false;

    nix.settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes" "pipe-operators"];
    };
  };

  flake.modules.nixos.nix-builder = {lib, ...}: let
    inherit (lib.lists) singleton;
  in {
    nix = {
      settings = {
        experimental-features = singleton "cgroups";
        use-cgroups = true;
        max-jobs = "auto";
        cores = 0;
        eval-cache = true;
        system-features = ["big-parallel" "kvm" "nixos-test"];

        trusted-users = singleton "@wheel";
        substituters = singleton "https://nix-community.cachix.org";
        trusted-public-keys = singleton "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
      };

      daemonCPUSchedPolicy = "idle";
      daemonIOSchedClass = "idle";

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };
  };
}
