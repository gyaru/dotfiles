{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.tack = pkgs.callPackage "${inputs.tack}/nix/package.nix" {};
  };
}
