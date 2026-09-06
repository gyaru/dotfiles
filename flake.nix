{
  description = "lis' nix flakes";

  nixConfig.extra-experimental-features = ["pipe-operators"];

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    hjem.follows = "hjem-rum/hjem";
    hjem-rum.url = "github:snugnug/hjem-rum";
    hjem-rum.inputs.nixpkgs.follows = "nixpkgs";
    noctalia.url = "github:noctalia-dev/noctalia";
    noctalia.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:sarunint/lanzaboote/xbootldr";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: let
    inherit (inputs.nixpkgs.lib.filesystem) listFilesRecursive;
    inherit (inputs.nixpkgs.lib.lists) filter;
    inherit (inputs.nixpkgs.lib.strings) hasSuffix;
  in
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = filter (hasSuffix ".mod.nix") (listFilesRecursive ./.);
    };
}
