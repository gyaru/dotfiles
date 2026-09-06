{
  config,
  flake,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkForce;
  inherit (lib.lists) singleton;
in {
  imports = [
    inputs.disko.nixosModules.disko
    flake.modules.nixos.base
    flake.modules.nixos.bunny-stream-gateway
    flake.modules.nixos.ssh
    flake.modules.nixos.tailscale
    flake.modules.nixos.firewall
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.kernel.sysctl."kernel.unprivileged_userns_clone" = mkForce 0;

  environment = {
    systemPackages = singleton pkgs.gitMinimal;
  };

  networking.firewall = {
    interfaces.tailscale0.allowedTCPPorts = config.services.openssh.ports ++ [9997];
    logRefusedConnections = false;
  };
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  nix.settings.trusted-users = ["root" "lis"];

  services = {
    openssh = {
      openFirewall = false;
      settings = {
        AllowUsers = singleton "lis";
        DisableForwarding = true;
        KbdInteractiveAuthentication = false;
        MaxAuthTries = 3;
      };
    };
    tailscale = {
      extraSetFlags = singleton "--accept-dns=false";
      openFirewall = true;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  users = {
    mutableUsers = false;
    users = {
      lis = {
        isNormalUser = true;
        extraGroups = singleton "wheel";
        hashedPassword = "!";
        openssh.authorizedKeys.keys = flake.people.lis.sshKeys ++ (singleton "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPRl/9b/3dl+A4HOv+MlZAHD7q0CF/4uMPvfG+tXD5fF hermes@gon-readonly");
      };
      root = {
        hashedPassword = "!";
      };
    };
  };

  system.stateVersion = "24.05";
}
