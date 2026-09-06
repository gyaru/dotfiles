_: {
  flake.modules.hjem.development = {
    config,
    pkgs,
    ...
  }: {
    environment.sessionVariables.RUSTUP_HOME = "${config.xdg.data.directory}/rustup";

    packages = with pkgs; [
      alejandra
      codex
      nil
      nix-direnv
      opencode
      socat
      strace
      vscode
    ];
  };
}
