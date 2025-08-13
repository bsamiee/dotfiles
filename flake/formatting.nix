# Title         : formatting.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : flake/formatting.nix
# ---------------------------------------
# Treefmt configuration module for code formatting
{ inputs, ... }:
{
  # --- Module Imports ------------------------------------------------------------
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  # --- Per-System Configuration -------------------------------------------------
  perSystem =
    { pkgs, ... }:
    {
      # --- Treefmt Configuration -------------------------------------------
      treefmt = {
        projectRootFile = "flake.nix";

        # --- Formatting Programs ------------------------------------------
        programs = {
          # --- Language-Specific Formatters -------------------------------
          nixfmt = {
            enable = true;
            package = pkgs.nixfmt-rfc-style;
          };
          shfmt = {
            enable = true;
            indent_size = 2;
          };
          mdformat = {
            enable = true;
          };
          taplo = {
            enable = true;
          };
          yamlfmt = {
            enable = true;
          };

          # --- Code Quality Tools -----------------------------------------
          shellcheck = {
            enable = true;
          };
          deadnix = {
            enable = true;
            no-lambda-arg = true;
            no-lambda-pattern-names = true;
          };
        };

        # --- Formatter Settings -------------------------------------------
        settings = {
          formatter = {
            nixfmt.excludes = [
              "*.md" # Don't format Nix code blocks in markdown
            ];
          };
          global.excludes = [
            "flake.lock"
            "result*"
            ".git/*"
          ];
          on-unmatched = "warn";
        };
      };
    };
}
