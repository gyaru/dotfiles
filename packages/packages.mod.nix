{lib, ...}: {
  perSystem = {pkgs, ...}: {
    packages = import ../lib/packages.nix {inherit lib pkgs;};
  };
}
