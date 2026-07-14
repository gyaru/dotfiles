{
  inputs,
  self,
}: {
  hostName,
  module,
}: let
  inherit (inputs.nixpkgs.lib) mkDefault nixosSystem;
in
  nixosSystem {
    specialArgs = {
      inherit inputs;
      flake = self;
    };

    modules = [
      {
        networking.hostName = mkDefault hostName;

        nixpkgs = {
          config.allowUnfree = true;
          overlays = [
            self.overlays.additions
            self.overlays.modifications
            self.overlays.unstable-packages
          ];
        };
      }
      module
    ];
  }
