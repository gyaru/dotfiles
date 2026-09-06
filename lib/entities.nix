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

  machines = {
    gon = {
      sshKeys = keys.gonSystemKeys;
      ssh.enable = true;
    };
    hana = {
      sshKeys = keys.hanaSystemKeys;
      ssh.enable = true;
    };
    lapi = {
      sshKeys = keys.systemKeys;
      ssh.enable = true;
    };
  };
}
