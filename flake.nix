{
  description = "lis' nix flakes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    anyrun.url = "github:Kirottu/anyrun";
    anyrun.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    ags.url = "github:aylur/ags";
    ags.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.pre-commit-hooks.flakeModule
      ];

      systems = ["x86_64-linux" "aarch64-darwin"];

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        packages = import ./pkgs pkgs;

        formatter = pkgs.alejandra;

        pre-commit = {
          check.enable = true;
          settings = {
            hooks = {
              alejandra.enable = true;
              deadnix.enable = true;
              statix.enable = true;
              nil.enable = true;
            };
          };
        };

        devShells.default = let
          scripts = ["pani"];
          mkScript = name: pkgs.writeShellScriptBin name (builtins.readFile ./scripts/${name}.sh);
        in
          pkgs.mkShell {
            name = "gyaru/nix-config";
            packages = with pkgs;
              [
                alejandra
                deadnix
                fd
                git
                nil
                nix-output-monitor
                shellcheck
                statix
              ]
              ++ map mkScript scripts;

            shellHook = ''
              ${config.pre-commit.installationScript}
              echo "lis' nix-config environment"
            '';
          };
      };

      flake = {
        overlays = import ./overlays {inherit inputs;};
        nixosModules = import ./modules/nixos;

        nixosConfigurations = {
          radiata = inputs.nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs;
              outputs = inputs.self;
            };
            modules = [
              ./hosts/radiata/configuration.nix
              inputs.lanzaboote.nixosModules.lanzaboote
              inputs.nix-index-database.nixosModules.nix-index
              inputs.home-manager.nixosModules.home-manager
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  backupFileExtension = "backup";
                  extraSpecialArgs = {inherit inputs;};
                  users.lis = import ./home/lis.nix;
                };
              }
            ];
          };
          lapi = inputs.nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs;
              outputs = inputs.self;
            };
            modules = [
              ./hosts/lapi/configuration.nix
              inputs.agenix.nixosModules.default
              inputs.nix-index-database.nixosModules.default
            ];
          };
        };

        darwinConfigurations = {
          carrot = inputs.darwin.lib.darwinSystem {
            specialArgs = {
              inherit inputs;
              outputs = inputs.self;
            };
            modules = [
              ./hosts/carrot/configuration.nix
              inputs.home-manager.darwinModules.home-manager
              {
                nixpkgs.overlays = [inputs.nixpkgs-firefox-darwin.overlay];
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = {inherit inputs;};
                  users.bun = import ./home/bun.nix;
                };
              }
            ];
          };
        };
      };
    };
}
