let
  entities = import ./lib/entities.nix;
  keys = import ./keys.nix;
  adminRecipients = keys.adminAgeKeys ++ entities.people.lis.sshKeys;
in {
  "secrets/lapi-smb.age".publicKeys = adminRecipients ++ [keys.radiataAgeKey];
  "secrets/k3s-token.age".publicKeys = adminRecipients ++ entities.machines.lapi.sshKeys;
  "secrets/flux-sops-age-key.age".publicKeys = adminRecipients ++ entities.machines.lapi.sshKeys;
  "secrets/gon-mediamtx-publisher-password.age".publicKeys = adminRecipients;
  "secrets/hana-wifi-password.age".publicKeys = adminRecipients ++ entities.machines.hana.sshKeys;
}
