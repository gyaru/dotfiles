let
  keys = import ./keys.nix;
in {
  "secrets/k3s-token.age".publicKeys = keys.adminSshKeys ++ keys.systemKeys;
}
