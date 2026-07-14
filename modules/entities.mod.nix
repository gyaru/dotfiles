_: let
  entities = import ../lib/entities.nix;
in {
  flake = {
    inherit (entities) adminSshKeys machines people;
  };
}
