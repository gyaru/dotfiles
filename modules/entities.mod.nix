{
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) attrsOf listOf nullOr port str strMatching submodule;
  entities = import ../lib/entities.nix;
  dnsName = strMatching "[A-Za-z0-9][A-Za-z0-9.-]*";
in {
  options.flake = {
    tailnet.dnsSuffix = mkOption {
      type = dnsName;
      description = "MagicDNS suffix used for SSH connections.";
    };

    people = mkOption {
      type =
        attrsOf
        <| submodule ({name, ...}: {
          options = {
            name = mkOption {
              type = str;
              default = name;
              description = "Display name.";
            };
            email = mkOption {
              type = nullOr str;
              default = null;
              description = "Email address.";
            };
            sshKeys = mkOption {
              type = listOf str;
              default = [];
              description = "User SSH public keys.";
            };
          };
        });
      default = {};
      description = "People using these machines.";
    };

    machines = mkOption {
      type =
        attrsOf
        <| submodule ({name, ...}: {
          options = {
            sshKeys = mkOption {
              type = listOf str;
              default = [];
              description = "Trusted SSH host public keys.";
            };
            ssh = {
              enable = mkEnableOption "a generated SSH client entry";
              alias = mkOption {
                type = dnsName;
                default = name;
                description = "Short SSH connection name.";
              };
              hostName = mkOption {
                type = dnsName;
                default = "${name}.${config.flake.tailnet.dnsSuffix}";
                description = "SSH destination in MagicDNS.";
              };
              user = mkOption {
                type = strMatching "[A-Za-z_][A-Za-z0-9_-]*";
                default = "lis";
                description = "Default SSH login user.";
              };
              port = mkOption {
                type = port;
                default = 22;
                description = "SSH server port.";
              };
            };
          };
        });
      default = {};
      description = "Machine identities and SSH connection settings.";
    };
  };

  config.flake = {
    inherit (entities) adminSshKeys machines people;
    tailnet.dnsSuffix = "tail254553.ts.net";
  };
}
