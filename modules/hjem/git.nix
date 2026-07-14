{
  flake,
  lib,
  pkgs,
  ...
}: {
  packages = [pkgs.gitMinimal];

  xdg.config.files."git/config" = {
    generator = lib.generators.toGitINI;
    value = {
      user = {
        inherit (flake.people.lis) name email;
      };

      init.defaultBranch = "main";
      fetch.fsckObjects = true;
      receive.fsckObjects = true;
      transfer.fsckObjects = true;
    };
  };
}
