let
  entities = import ./lib/entities.nix;
in {
  "secrets/k3s-token.age".publicKeys = entities.adminSshKeys ++ entities.machines.lapi.sshKeys;
  "secrets/kodi-password.age".publicKeys = entities.adminSshKeys ++ entities.machines.lapi.sshKeys;
  "secrets/flux-sops-age-key.age".publicKeys = entities.adminSshKeys ++ entities.machines.lapi.sshKeys;
}
