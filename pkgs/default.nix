pkgs: let
  packages = [
    "mplus-fonts"
    "balsamiqsans"
    "lucide-icons"
    "curseforge"
  ];
in
  builtins.listToAttrs (map (name: {
      inherit name;
      value = pkgs.callPackage (./. + "/${name}") {};
    })
    packages)
