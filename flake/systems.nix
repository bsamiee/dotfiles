# Title         : systems.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : flake/systems.nix
# ---------------------------------------
# Darwin and Home Manager system configurations
{ inputs, userConfig, mkUserConfig, ... }:
{
  # --- Flake Configuration ------------------------------------------------------
  flake =
    let
      inherit (inputs)
        nixpkgs
        darwin
        home-manager
        nix-homebrew
        ;
      # --- Universal System Configuration Helper ----------------------------
      mkDarwinSystem =
        { system, username ? null }:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs system;
            userConfig = if username != null then mkUserConfig username else userConfig;
            myLib = import ../lib {
              inherit inputs;
              inherit (nixpkgs) lib;
            };
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          };
          modules = [
            ../lib/assertions.nix
            ../darwin/hosts/default.nix
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs system userConfig;
                  myLib = import ../lib {
                    inherit inputs;
                    inherit (nixpkgs) lib;
                  };
                };
                users.${userConfig.username} = ../home/default.nix;
              };
            }
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                enableRosetta = system == "aarch64-darwin";
                user = userConfig.username;
                autoMigrate = true;
              };
            }
          ];
        };
      # --- Standalone Home Manager Helper -----------------------------------
      mkHomeConfiguration =
        { system }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          modules = [ ../home/default.nix ];
          extraSpecialArgs = {
            inherit inputs system userConfig;
            myLib = import ../lib {
              inherit inputs;
              inherit (nixpkgs) lib;
            };
          };
        };
    in
    {
      # --- Universal Darwin Configurations ----------------------------------
      darwinConfigurations = 
        let
          # Detect runtime user if possible
          runtimeUser = builtins.getEnv "TARGET_USER";
          effectiveUser = if runtimeUser != "" then runtimeUser else null;
        in {
        default = mkDarwinSystem {
          system = "aarch64-darwin";
          username = effectiveUser;
        };
        aarch64 = mkDarwinSystem {
          system = "aarch64-darwin";
          username = effectiveUser;
        };
        x86_64 = mkDarwinSystem {
          system = "x86_64-darwin";
          username = effectiveUser;
        };
      };
      # --- Universal Home Manager Configurations ----------------------------
      homeConfigurations = {
        default = mkHomeConfiguration {
          system = "aarch64-darwin";
        };
        aarch64 = mkHomeConfiguration {
          system = "aarch64-darwin";
        };
        x86_64 = mkHomeConfiguration {
          system = "x86_64-darwin";
        };
      };
    };

  # --- Per-System Configuration -------------------------------------------------
  perSystem =
    { system, ... }:
    {
      # --- Universal Package Access ---------------------------------------------
      packages = {
        darwin-system = inputs.self.darwinConfigurations.default.system;
        home-config = inputs.self.homeConfigurations.default.activationPackage;
        darwin-aarch64 = inputs.self.darwinConfigurations.aarch64.system;
        darwin-x86_64 = inputs.self.darwinConfigurations.x86_64.system;
        home-aarch64 = inputs.self.homeConfigurations.aarch64.activationPackage;
        home-x86_64 = inputs.self.homeConfigurations.x86_64.activationPackage;
        default = inputs.self.darwinConfigurations.default.system;
        darwin = inputs.self.darwinConfigurations.default.system;
        home = inputs.self.homeConfigurations.default.activationPackage;
      };
    };
}
