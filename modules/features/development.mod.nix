{self, ...}: {
  flake.modules.hjem.development = {
    config,
    pkgs,
    ...
  }: {
    environment.sessionVariables.RUSTUP_HOME = "${config.xdg.data.directory}/rustup";

    packages = with pkgs; [
      alejandra
      nil
      nix-direnv
      socat
      git
      strace
      self.packages.${pkgs.stdenv.hostPlatform.system}.slop
      vscode
    ];
  };
}
