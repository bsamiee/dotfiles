# Title         : development.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/modules/packages/development.nix
# ---------------------------------------
# General development tools - build systems, code quality, testing, and automation

{ pkgs, ... }:

with pkgs;
[
  pre-commit # NEW TOOL ADDED - PENDING CONFIGURATION - Git hook framework

  # --- Code Quality & Linting --------------------------------------------------
  shellcheck # Shell script linter
  shfmt # Shell formatter
  bash-language-server # LSP for shell scripts
  sqlfluff # SQL linter and formatter

  # --- Config File Language Servers --------------------------------------------
  taplo # TOML formatter and linter
  taplo-lsp # TOML language server
  yamlfmt # YAML formatter (Google's, no Python deps)
  yamllint # YAML linter
  yaml-language-server # YAML language server
  marksman # Markdown LSP with wiki-link support

  # --- Data Processing ----------------------------------------------------------
  yq-go # YAML processor (Go version)
  fx # Interactive JSON viewer
  jless # JSON pager
  xan # CSV toolkit (xsv replacement)

  # --- Archive & Compression ---------------------------------------------------
  unzip # Utilities for zip archives
  zip # Create zip archives
  zstd # Zstandard compression
  xz # XZ compression utilities
  lz4 # Extremely fast compression
  brotli # Generic-purpose lossless compression

  # --- Core GNU Utilities (newer versions than macOS defaults) -----------------
  coreutils # GNU core utilities (ls, cp, mv, etc.)
  findutils # GNU find, xargs, etc.
  gnugrep # GNU grep
  gnused # GNU sed
  gawk # GNU awk
  bash # Bash shell (newer version than macOS default)
  gnutar # GNU version of tar
  diffutils # GNU diff utilities
]
