# Title         : scripts.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/modules/scripts.nix
# ---------------------------------------
# Nix-native script management using writeShellApplication

{
  pkgs,
  lib,
  myLib,
  ...
}:

let
  # --- Helper Functions ---------------------------------------------------------
  # Use centralized mkScript helper from lib
  mkScript = myLib.mkScript pkgs;

  # --- User Utility Scripts ----------------------------------------------------
  userScripts = {
    audit-tools = mkScript {
      name = "audit-tools";
      description = "Comprehensive tool audit with detailed table output";
      deps = [ ]; # All deps in core.nix: coreutils, gnugrep, gawk, findutils, gnused
      text = builtins.readFile ../../bin/audit-tools.sh;
    };
  };

  # --- System Management Scripts -----------------------------------------------
  systemScripts = {
    rebuild = mkScript {
      name = "rebuild";
      description = "Smart Nix Darwin rebuild script";
      deps = [ ]; # All deps globally available: nixVersions.latest (nix-tools), git, coreutils (core)
      text = builtins.readFile ../../scripts/rebuild.sh;
    };

    cachix-manager = mkScript {
      name = "cachix-manager";
      description = "Cachix cache management";
      deps = [ ]; # All deps globally available: cachix, nixVersions.latest (nix-tools), jq, coreutils (core)
      text = builtins.readFile ../../scripts/cachix.sh;
    };

    deploy = mkScript {
      name = "deploy";
      description = "Nix deployment script";
      deps = [ ]; # All deps globally available: deploy-rs, nixVersions.latest (nix-tools), openssh, rsync (core)
      text = builtins.readFile ../../scripts/deploy.sh;
    };

    nix-health = mkScript {
      name = "nix-health";
      description = "Nix store health check";
      deps = [ ]; # All deps globally available: nixVersions.latest (nix-tools), coreutils, gnugrep, gawk (core)
      text = builtins.readFile ../../scripts/nix-health.sh;
    };

    secrets-manager = mkScript {
      name = "secrets-manager";
      description = "Unified secrets management with 1Password";
      deps = [ ]; # All deps globally available: _1password-cli (macos.nix), jq (core.nix)
      text = builtins.readFile ../../scripts/secrets-manager.sh;
    };
  };

  # --- Bootstrap Scripts -------------------------------------------------------
  # Special handling - not in PATH but available for initial setup
  bootstrapScripts = {
    bootstrap = mkScript {
      name = "bootstrap";
      description = "System bootstrap script";
      deps = [ ]; # All deps globally available: nixVersions.latest (nix-tools), git, curl, coreutils (core)
      text = builtins.readFile ../../scripts/bootstrap.sh;
    };

  };

in
{
  # --- Package Exports ---------------------------------------------------------
  home.packages = (lib.attrValues userScripts) ++ (lib.attrValues systemScripts);

  # --- Bootstrap Script Deployment ---------------------------------------------
  # Available at ~/.local/share/dotfiles/ for manual execution
  home.file = {
    ".local/share/dotfiles/bootstrap.sh" = {
      source = "${bootstrapScripts.bootstrap}/bin/bootstrap";
      executable = true;
    };
  };
}
