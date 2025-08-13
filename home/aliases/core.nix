# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/shells/aliases/core.nix
# ---------------------------------------
# Core development tools - Unix replacements + cross-language dev infrastructure

{ lib, ... }:

let
  # --- Cross-Language Development Tools (dynamically prefixed) ------------------
  prettierCommands = {
    # Prettier format, lint, reporting - consolidated
    fmt = "f() { prettier --write \"\${@:-.}\"; }; f"; # fmt - format files (consolidated)
    lint = "f() { prettier --check \"\${@:-.}\"; }; f"; # lint - check formatting (unified semantic)
    report = "f() { prettier --list-different \"\${@:-.}\"; }; f"; # preport - comprehensive report
  };
  eslintCommands = {
    # eslint format, lint, reporting - consolidated
    lint = "f() { eslint \"\${@:-.}\"; }; f"; # elint - check for issues (unified semantic)
    lintf = "f() { eslint --fix \"\${@:-.}\"; }; f"; # elintf - auto-fix issues (unified semantic)
    report = "f() { eslint -f json \"\${@:-.}\"; }; f"; # ereport - comprehensive JSON report
  };
  typescriptCommands = {
    # TypeScript format, lint, reporting - consolidated
    sc = "tsc"; # tsc - compile (shorter alias) #CONFIRM THIS - IT SEEMS WRONG WITH THE DYNAMIC GENERATOR WOULD BE TSSC?
    check = "tsc --noEmit"; # tscheck - check without output
    watch = "tsc --watch"; # tswatch - watch mode
  };
  tomlCommands = {
    # TOML format, lint, reporting - consolidated
    fmt = "f() { taplo fmt \"\${@:-.}\"; }; f"; # tomlfmt - format TOML files
    lint = "f() { taplo lint \"\${@:-.}\"; }; f"; # tomllint - lint TOML files
  };
  yamlCommands = {
    # YAML format, lint, reporting - consolidated
    fmt = "f() { yamlfmt \"\${@:-.}\"; }; f"; # yfmt - format YAML files
    lint = "f() { yamllint \"\${@:-.}\"; }; f"; # ylint - lint YAML files
  };
  prettierAliases = lib.mapAttrs' (name: value: {
    name = "p${name}";
    inherit value;
  }) prettierCommands;
  eslintAliases = lib.mapAttrs' (name: value: {
    name = "e${name}";
    inherit value;
  }) eslintCommands;
  typescriptAliases = lib.mapAttrs' (name: value: {
    name = "ts${name}";
    inherit value;
  }) typescriptCommands;
  tomlAliases = lib.mapAttrs' (name: value: {
    name = "toml${name}";
    inherit value;
  }) tomlCommands;
  yamlAliases = lib.mapAttrs' (name: value: {
    name = "y${name}";
    inherit value;
  }) yamlCommands;
in
{
  aliases = {
    # --- Development Environment Launcher ----------------------------------------
    dev = "dev-env.sh"; # Universal development environment launcher
    devls = "dev-env.sh --list"; # List available development environments
    devdetect = "dev-env.sh --detect"; # Detect project type from current directory

    # --- Universal Quality Assurance Functions -----------------------------------
    # Smart qa/qaf that detects file type and delegates to appropriate tool
    qa = ''
      f() {
            for file in "''${@:-.}"; do
              if [[ -f "$file" ]]; then
                ext="''${file##*.}"
                case "$ext" in
                  nix) deadnix --hidden --no-underscore --fail "$file" && statix check "$file" && nixfmt --check "$file" ;;
                  sh) shellcheck "$file" && shfmt -ci -i 4 -d "$file" ;;
                  toml) taplo lint "$file" ;;
                  yaml|yml) yamllint "$file" ;;
                  js|jsx|ts|tsx|json) elint "$file" && plint "$file" ;;
                  py) echo "Use 'ruff check' for Python files" ;;
                  *) echo "Unknown file type: $ext" ;;
                esac
              elif [[ -d "$file" ]]; then
                echo "Checking directory: $file"
                find "$file" -name "*.nix" -exec bash -c 'deadnix --hidden --no-underscore --fail {} && statix check {} && nixfmt --check {}' \; 2>/dev/null || true
                find "$file" -name "*.sh" -exec bash -c 'shellcheck {} && shfmt -ci -i 4 -d {}' \; 2>/dev/null || true
              fi
            done
          }; f''; # Universal quality check

    qaf = ''
      f() {
            for file in "''${@:-.}"; do
              if [[ -f "$file" ]]; then
                ext="''${file##*.}"
                case "$ext" in
                  nix) deadnix --hidden --no-underscore --edit "$file" && statix fix "$file" && nixfmt "$file" ;;
                  sh) shfmt -ci -i 4 -w "$file" && shellcheck "$file" ;;
                  toml) taplo fmt "$file" ;;
                  yaml|yml) yamlfmt "$file" && yamllint "$file" ;;
                  js|jsx|ts|tsx|json) elintf "$file" && pfmt "$file" ;;
                  py) echo "Use 'ruff format' for Python files" ;;
                  *) echo "Unknown file type: $ext" ;;
                esac
              elif [[ -d "$file" ]]; then
                echo "Fixing directory: $file"
                find "$file" -name "*.nix" -exec bash -c 'deadnix --hidden --no-underscore --edit {} && statix fix {} && nixfmt {}' \; 2>/dev/null || true
                find "$file" -name "*.sh" -exec bash -c 'shfmt -ci -i 4 -w {} && shellcheck {}' \; 2>/dev/null || true
              fi
            done
          }; f''; # Universal quality fix

    # --- Modern Unix Command Replacements ----------------------------------------
    # NOTE: Core Unix replacements moved to consolidated-core.nix
    # These use smart wrappers from lib/command-wrapper.sh

    # TODO: Add these as you install and verify the tools:
    # time = "hyperfine"; # Better benchmarking/timing tool
    # df = "duf";         # Better disk usage
    # ps = "procs";       # Better process viewer
    # top = "btop";       # Better system monitor
    # dig = "dog";        # Better DNS lookup
    # ping = "gping";     # Ping with graph
    # du = "dust";        # Better disk usage analyzer
    # watch = "viddy";    # Better watch with history/diff
  }
  # --- Cross-Language Development Tools (foundational) -------------------------
  // prettierAliases # p* - prettier formatting (JS, JSON, MD, CSS, HTML - excludes YAML)
  // eslintAliases # e* - eslint linting (JS, TS, JSON)
  // typescriptAliases # ts* - typescript compilation
  // tomlAliases # toml* - TOML formatting and linting via taplo
  // yamlAliases; # y* - YAML formatting and linting via yamlfmt/yamllint
}
