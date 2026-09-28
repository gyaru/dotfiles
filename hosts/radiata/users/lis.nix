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
      flake.modules.hjem."battle.net"
      flake.modules.hjem.yubikey
    ];

    users.lis = {
      enable = true;
      user = "lis";
      directory = "/home/lis";
    };
  };
}
