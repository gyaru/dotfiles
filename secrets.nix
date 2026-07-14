let
  entities = import ./lib/entities.nix;
in {
  "secrets/k3s-token.age".publicKeys = entities.adminSshKeys ++ entities.machines.lapi.sshKeys;
}
