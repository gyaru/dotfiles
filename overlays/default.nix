{inputs, ...}: {
  additions = final: prev:
    import ../lib/packages.nix {
      inherit (prev) lib;
      pkgs = final;
    };

  modifications = _: _: {
  };

  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };
}
