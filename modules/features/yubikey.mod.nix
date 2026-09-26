{inputs, ...}: {
  flake.modules.nixos.yubikey = {
    services.pcscd.enable = true;

    security = {
      pam = {
        u2f.settings.cue = true;

        services.sudo.u2f = {
          enable = true;
          control = "sufficient";
        };
      };

      sudo.wheelNeedsPassword = true;
    };
  };

  flake.modules.hjem.yubikey = {pkgs, ...}: {
    packages = [
      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.age
      pkgs.age-plugin-yubikey
      pkgs.yubikey-manager
      pkgs.pam_u2f
    ];
  };
}
