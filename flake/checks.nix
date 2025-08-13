# Title         : checks.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : flake/checks.nix
# ---------------------------------------
# Automated quality checks for CI/CD and pre-commit validation

{ userConfig, ... }:
{
  # --- Per-System Configuration -------------------------------------------------
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      # --- Quality Checks --------------------------------------------------------
      checks = {
        # --- Evaluation Check (No Build) ----------------------------------------
        evaluation = pkgs.runCommandLocal "evaluation-check" 
          { 
            src = lib.cleanSource ../..;
            nativeBuildInputs = [ pkgs.nix ];
          } ''
          echo "Checking flake evaluation without building..."
          cd $src

          # Test that darwin configuration evaluates without errors
          if ! nix eval .#darwinConfigurations.default.system.drvPath >/dev/null 2>&1; then
            echo "ERROR: Darwin configuration failed to evaluate"
            exit 1
          fi

          # Test that home-manager configuration evaluates without errors
          if ! nix eval .#homeConfigurations.default.activationPackage.drvPath >/dev/null 2>&1; then
            echo "ERROR: Home-Manager configuration failed to evaluate"
            exit 1
          fi

          echo "All configurations evaluated successfully"
          touch $out
        '';

        # --- Linting and Code Quality (Unified via treefmt) -------------------
        # Note: treefmt check is automatically provided via treefmt-nix

        # --- Individual Linting Tools (Fallback) -------------------------------
        statix =
          pkgs.runCommandLocal "statix-check"
            {
              src = lib.cleanSource ../..;
              nativeBuildInputs = [ pkgs.statix ];
            }
            ''
              echo "Running statix linter..."
              statix check $src
              touch $out
            '';
        deadnix =
          pkgs.runCommandLocal "deadnix-check"
            {
              src = lib.cleanSource ../..;
              nativeBuildInputs = [ pkgs.deadnix ];
            }
            ''
              echo "Checking for dead code..."
              deadnix --hidden --no-underscore --fail $src
              touch $out
            '';
        nil-diagnostics =
          pkgs.runCommandLocal "nil-diagnostics"
            {
              src = lib.cleanSource ../..;
              nativeBuildInputs = [
                pkgs.nil
                pkgs.findutils
              ];
            }
            ''
              echo "Running nil diagnostics..."
              find $src -name "*.nix" -type f -exec nil diagnostics {} \;
              touch $out
            '';
        # --- Configuration Validation ------------------------------------------
        validate-config = pkgs.runCommand "validate-config" { } ''
          echo "Validating user configuration..."

          # Email validation
          if ! echo "${userConfig.gitEmail}" | grep -qE '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'; then
            echo "ERROR: Invalid email format: ${userConfig.gitEmail}"
            exit 1
          fi

          # Path validation
          if [ ! -d "${userConfig.flakeRoot}" ]; then
            echo "WARNING: Flake root does not exist: ${userConfig.flakeRoot}"
          fi

          echo "Configuration validated successfully"
          touch $out
        '';
        flake-structure = pkgs.runCommandLocal "flake-structure-check" 
          { 
            src = lib.cleanSource ../..;
            nativeBuildInputs = [ pkgs.nix ];
          } ''
          echo "Validating flake structure..."
          cd $src

          # Check that required outputs exist without recursive flake check
          if [ ! -f "flake.nix" ]; then
            echo "ERROR: flake.nix not found in $src"
            exit 1
          fi

          # Validate flake.nix syntax
          if ! nix-instantiate --parse "flake.nix" >/dev/null 2>&1; then
            echo "ERROR: flake.nix has syntax errors"
            exit 1
          fi

          echo "Flake structure validated successfully"
          touch $out
        '';
      };
    };
}
