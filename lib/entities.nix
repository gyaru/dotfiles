let
  keys = import ../keys.nix;
in {
  inherit (keys) adminSshKeys;

  people = {
    lis = {
      name = "gyaru";
      email = "gyaru@users.noreply.github.com";
      sshKeys = keys.lisKeys;
    };

    mikan.sshKeys = keys.mikanKeys;
  };

  machines.lapi.sshKeys = keys.systemKeys;
}
