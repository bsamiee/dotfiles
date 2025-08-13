# Title         : shell-tools.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/shells/aliases/shell-tools.nix
# ---------------------------------------
# Shell scripting development aliases - unified namespace for shell tools

{ lib, ... }:

let
  # --- Shell Commands (dynamically prefixed with 's') ---------------------------
  shellCommands = {
    # Core formatting & linting (unified semantics)
    fmt = "f() { shfmt -ci -i 4 -w \"\${@:-.}\"; }; f"; # sfmt - format files (consolidated)
    lint = "f() { shellcheck \"\${@:-.}\"; }; f"; # slint - check for issues (unified semantic)
    lintf = "f() { echo 'Note: shellcheck cannot auto-fix, showing diff format:' && shellcheck -f diff \"\${@:-*.sh}\"; }; f"; # slintf - show fixes (unified semantic)
    report = "f() { qa-report.sh shell \"\${@:-.}\"; }; f"; # sreport - comprehensive report

    # Shell execution with intelligent error handling
    run = "f() { set -euo pipefail; \"\$@\"; }; f"; # srun - execute with strict error handling
    trace = "f() { set -x; \"\$@\"; set +x; }; f"; # strace - trace execution
    check = "f() { bash -n \"\${@:-*.sh}\"; }; f"; # scheck - syntax check only

    # Development utilities (consolidated)
    find = "f() { shfmt -f \"\${1:-.}\"; }; f"; # sfind - find shell files in directory
    simplify = "f() { shfmt -s -ci -i 4 -w \"\${@:-.}\"; }; f"; # ssimplify - simplify and format

    # Documentation & help
    help = "echo 'Shell tools: shellcheck.net | github.com/mvdan/sh'"; # shelp
    version = "shellcheck --version | head -2 && shfmt --version"; # sversion
  };
in
{
  aliases = lib.mapAttrs' (name: value: {
    # Export aliases with 's' prefix
    name = "s${name}";
    inherit value;
  }) shellCommands;
}
