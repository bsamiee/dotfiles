# Title         : nix-tools.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/modules/packages/nix-tools.nix
# ---------------------------------------
# Nix ecosystem development and maintenance tools

{ pkgs, ... }:

with pkgs;
[
  # --- Core Nix Toolchain -------------------------------------------------------
  nixVersions.latest # Latest Nix (used by rebuild, cachix-manager, deploy, nix-health scripts)
  cachix # Binary cache management (used by cachix-manager script)
  deploy-rs # NixOS deployment tool (used by deploy script)

  # --- Build & Development Tools ------------------------------------------------
  nix-output-monitor # Pretty output for Nix builds (used in nb, nd aliases)
  nix-fast-build # Parallel evaluation and building for 90% performance gain
  nix-index # Package search by file contents (provides nix-locate command)

  # --- Language Server & Code Quality -------------------------------------------
  nil # Nix language server for IDE integration
  deadnix # Find and remove dead code in Nix files
  statix # Lints and suggestions for Nix code
  nixfmt-rfc-style # Official Nix code formatter
]
