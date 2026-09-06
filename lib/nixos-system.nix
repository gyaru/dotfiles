{
  inputs,
  self,
}: {
  hostName,
  module,
}: let
  inherit (inputs.nixpkgs.lib.modules) mkDefault;
  inherit (inputs.nixpkgs.lib) nixosSystem;
in
  nixosSystem {
    specialArgs = {
      inherit inputs;
      flake = self;
    };

    modules = [
      self.modules.nixos.nix
      self.modules.nixos.ssh-client
      {
        networking.hostName = mkDefault hostName;

        nixpkgs = {
          config.allowUnfree = true;
          overlays = [
            self.overlays.additions
            self.overlays.modifications
          ];
        };
      }
      module
    ];
  }
