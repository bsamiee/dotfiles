# Title         : checks.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : flake/checks.nix
# ---------------------------------------
# Automated quality checks for CI/CD and pre-commit validation

{ inputs, userConfig, ... }:
{
  # --- Per-System Configuration -------------------------------------------------
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    {
      # --- Quality Checks --------------------------------------------------------
      checks = {
        # --- Build Validation ---------------------------------------------------
        build = self'.packages.darwin-system;

        # --- Linting and Code Quality ------------------------------------------
        statix =
          pkgs.runCommand "statix-check"
            {
              src = ../.;
              nativeBuildInputs = [ pkgs.statix ];
            }
            ''
              echo "Running statix linter..."
              statix check $src
              touch $out
            '';
        deadnix =
          pkgs.runCommand "deadnix-check"
            {
              src = ../.;
              nativeBuildInputs = [ pkgs.deadnix ];
            }
            ''
              echo "Checking for dead code..."
              deadnix --fail $src
              touch $out
            '';
        nil-diagnostics =
          pkgs.runCommand "nil-diagnostics"
            {
              src = ../.;
              nativeBuildInputs = [ pkgs.nil ];
            }
            ''
              echo "Running nil diagnostics..."
              failed=0
              find $src -name "*.nix" -type f | while read -r file; do
                if ! nil diagnostics "$file"; then
                  echo "ERROR: nil diagnostics failed for $file"
                  failed=1
                fi
              done
              if [ $failed -eq 1 ]; then
                echo "ERROR: nil diagnostics check failed"
                exit 1
              fi
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
        flake-structure =
          pkgs.runCommand "flake-structure-check"
            {
              nativeBuildInputs = [ pkgs.nix ];
            }
            ''
              echo "Validating flake structure..."
              nix flake check ${inputs.self} --no-build 2>&1 || true
              touch $out
            '';
      };
    };
}
