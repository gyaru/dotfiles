{inputs, ...}: {
  flake.modules.nixos.home = inputs.hjem.nixosModules.default;

  flake.modules.hjem.home = {config, ...}: {
    environment.sessionVariables = {
      XDG_CACHE_HOME = config.xdg.cache.directory;
      XDG_CONFIG_HOME = config.xdg.config.directory;
      XDG_DATA_HOME = config.xdg.data.directory;
      XDG_STATE_HOME = config.xdg.state.directory;
    };
  };
}
