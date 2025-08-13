# Title         : devshells.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : flake/devshells.nix
# ---------------------------------------
# Development shells configuration
{ inputs, userConfig, ... }:
{
  # --- Per-System Configuration -------------------------------------------------
  perSystem =
    {
      lib,
      pkgs,
      ...
    }:
    {
      # --- Development Shells ---------------------------------------------------
      devShells = {
        # Default Nix development shell (occasional analysis tools only)
        default = pkgs.mkShell {
          name = "dotfiles-dev";

          packages = with pkgs; [
            # --- Package Management and Review ------------------------------------
            nix-eval-jobs # Parallel evaluation
            nixpkgs-review # Review nixpkgs changes
            flake-checker # Check flake health
            nix-fast-build # Fast parallel building
            home-manager # Home-manager CLI

            # --- Code Quality Tools (TEMPORARY) -----------------------------------
            # TODO: Remove after darwin-rebuild switch - these will be globally available
            nixfmt-rfc-style # Nix code formatter
            deadnix # Find dead code
            statix # Nix linter
            nil # Nix language server

            # --- Nix Analysis and Visualization ----------------------------------
            nix-tree # Interactive dependency explorer
            nix-du # Store space analyzer
            nix-diff # Derivation-level comparison
            nvd # Generation-level comparison
            nix-visualize # Static dependency graphs
            graphviz # Graph visualization (dependency for nix-visualize)
          ];

          shellHook = ''
            echo "═══════════════════════════════════════════════════════"
            echo "  Dotfiles Analysis & Review Environment"
            echo "═══════════════════════════════════════════════════════"
            echo ""
            echo "🔍 Analysis Tools (occasional use):"
            echo "  nix-tree          - Interactive dependency browser"
            echo "  nix-du            - Store space analyzer"
            echo "  nix-diff          - Compare derivations"
            echo "  nvd               - Compare generations"
            echo "  nix-visualize     - Generate dependency graphs"
            echo ""
            echo "📦 Package Tools:"
            echo "  nixpkgs-review    - Review nixpkgs changes"
            echo "  flake-checker     - Check flake health"
            echo "  nix-eval-jobs     - Parallel evaluation"
            echo ""
            echo "💡 Daily tools available globally:"
            echo "  nfmt, nlint, ndead - Code quality (via aliases)"
            echo "  git, jq, cachix   - Core tools (permanent install)"
            echo ""
            echo "🚀 Quick commands:"
            echo "  nix fmt           - Format all code"
            echo "  nix flake check   - Validate configuration"
            echo "  exit              - Leave development shell"
            echo ""
          '';
        };

        # --- Python Development Shell --------------------------------------------
        python = import ./devshells/python.nix {
          inherit pkgs lib userConfig;
          myLib = import ../lib { inherit inputs lib; };
        };

        # --- Lua Development Shell -----------------------------------------------
        lua = import ./devshells/lua.nix {
          inherit pkgs lib userConfig;
          myLib = import ../lib { inherit inputs lib; };
        };

        # --- Rust Development Shell -------------------------------------------
        rust = import ./devshells/rust.nix {
          inherit pkgs lib userConfig;
          myLib = import ../lib { inherit inputs lib; };
        };
      };
    };
}
