# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : lib/default.nix
# ---------------------------------------
# Reusable lib helpers - Only actively used functions
{
  lib ? (import <nixpkgs> { }).lib,
  ...
}:
let
  # --- Platform checks ---------------------------------------------
  isDarwin = system: system == "aarch64-darwin" || system == "x86_64-darwin";

  # --- Package Management Helpers ----------------------------------
  # Create a boolean option for package suites with consistent structure
  mkPackageEnable =
    description: default:
    lib.mkOption {
      type = lib.types.bool;
      inherit default description;
    };

  # --- Script Creation Helper --------------------------------------
  # Create a script using writeShellApplication with standard options
  mkScript =
    pkgs:
    {
      name,
      deps ? [ ],
      text,
      description ? "",
    }:
    pkgs.writeShellApplication {
      inherit name text;
      runtimeInputs = deps;
      meta = { inherit description; };
    };
in
{
  inherit
    isDarwin
    mkPackageEnable
    mkScript
    ;
  # Re-export commonly used lib functions for convenience
  default = lib.mkDefault;
  order = lib.mkOrder;
}
