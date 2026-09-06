{self, ...}: {
  flake.modules.hjem.git = {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.lists) singleton;
    inherit (lib.generators) toGitINI;
  in {
    packages = singleton pkgs.gitMinimal;

    xdg.config.files."git/config" = {
      generator = toGitINI;
      value = {
        user = {
          inherit (self.people.lis) name email;
        };

        init.defaultBranch = "main";
        fetch.fsckObjects = true;
        receive.fsckObjects = true;
        transfer.fsckObjects = true;
      };
    };
  };
}
