{
  flake,
  inputs,
  ...
}: {
  hjem = {
    clobberByDefault = true;
    extraModules = [
      inputs.hjem-rum.hjemModules.default
      flake.modules.hjem.workstation
    ];

    users.lis = {
      enable = true;
      user = "lis";
      directory = "/home/lis";
    };
  };
}
