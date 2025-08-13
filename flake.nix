# Title         : flake.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# ---------------------------------------
# Main entry point - configures Nix flake with dynamic user detection and multi-architecture support

{
  description = "macOS: nix-darwin + home-manager";

  nixConfig = {
    warn-dirty = false;
    accept-flake-config = true;
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    inputs@{ flake-parts, ... }:
    let
      # --- Dynamic System Detection ---------------------------------------------
      # Default user config - will be overridden at deployment time if needed
      defaultUserConfig = rec {
        username = "bardiasamiee";  # Default, overridden by deployment
        gitUsername = "bsamiee";
        gitEmail = "b.samiee93@gmail.com";
        userHome = "/Users/${username}";
        flakeRoot = "${userHome}/.dotfiles";
      };
      
      # Function to create user config with custom username
      mkUserConfig = username: defaultUserConfig // rec {
        inherit username;
        userHome = "/Users/${username}";
        flakeRoot = "${userHome}/.dotfiles";
      };
      # --- System Architecture Detection ------------------------------------
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = supportedSystems;
      imports = [
        ./flake/formatting.nix
        ./flake/devshells.nix
        ./flake/deploy.nix
        ./flake/systems.nix
        ./flake/checks.nix
      ];
      _module.args = {
        userConfig = defaultUserConfig;
        inherit mkUserConfig;
      };
    };
}
