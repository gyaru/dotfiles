{self, ...}: {
  flake.modules.nixos.ssh-client = {lib, ...}: let
    inherit (lib.attrsets) attrValues filterAttrs listToAttrs mapAttrsToList nameValuePair;
    inherit (lib.lists) concatMap imap0 unique;
    inherit (lib.strings) concatMapStringsSep;
    machines = filterAttrs (_: {ssh, ...}: ssh.enable) self.machines;
  in {
    assertions =
      mapAttrsToList (name: {sshKeys, ...}: {
        assertion = sshKeys != [];
        message = "SSH client entry ${name} requires a trusted host public key.";
      })
      machines;

    programs.ssh.extraConfig =
      concatMapStringsSep "\n" ({ssh, ...}:
        /*
        ssh_config
        */
        ''
          Host ${ssh.alias} ${ssh.hostName}
            HostName ${ssh.hostName}
            User ${ssh.user}
            Port ${toString ssh.port}
        '') (attrValues machines)
      + "\nHost *\n";

    programs.ssh.knownHosts =
      listToAttrs
      <| concatMap (
        {
          ssh,
          sshKeys,
          ...
        }:
          imap0 (index: publicKey:
            nameValuePair "tailnet-${ssh.alias}-${toString index}" {
              inherit publicKey;
              hostNames = map (
                host:
                  if ssh.port == 22
                  then host
                  else "[${host}]:${toString ssh.port}"
              ) (unique [ssh.alias ssh.hostName]);
            })
          sshKeys
      ) (attrValues machines);
  };

  flake.modules.nixos.ssh = {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
}
