# Title         : file-management.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/modules/file-management.nix
# ---------------------------------------
# Centralized file management for all configuration files and XDG baseline setup

{
  pkgs,
  lib,
  ...
}:

{
  # --- XDG Baseline Setup ---------------------------------------------------
  xdg = {
    enable = true; # Enable home-manager's XDG support
    # XDG user directories are Linux-only, so we skip them on Darwin
    # The darwin module already handles directory creation
    # XDG MIME applications are also Linux-only
    # File associations are handled in darwin/modules/file-management.nix
    # Note: XDG environment variables have been consolidated in home/modules/environment.nix
    # Shell-specific XDG configurations are handled in their respective modules
    # zsh.nix already sets history.path to ${config.xdg.dataHome}/zsh/history

    # Configuration files managed by home-manager
    configFile = {
      # User-specific git config (uses system XDG paths)
      "git/ignore".source = ../configs/git/gitignore;
      "git/attributes".source = ../configs/git/gitattributes;
    };

    # Data files
    # Desktop entries are Linux-specific and not needed on macOS
    # macOS uses .app bundles for application management
    dataFile = lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
      # Application desktop entries for better integration (Linux only)
      "applications/code.desktop" = {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=Visual Studio Code
          Exec=code %F
          Icon=code
          MimeType=text/plain;text/x-shellscript;application/json;
        '';
      };
    };
  };

  # --- Configuration Files ---------------------------------------------------
  home.file = {
    # --- Terminal Configuration ---------------------------------------------
    ".config/wezterm/wezterm.lua".source = ../configs/apps/wezterm.lua;

    # --- Language Server & Development Configs -----------------------------
    # Nix LSP
    ".nil.toml".source = ../configs/languages/nil.toml;
    # TypeScript/JavaScript LSP
    ".config/typescript/tsconfig.json".source = ../configs/languages/tsconfig.json;
    ".config/eslint/eslint.config.js".source = ../configs/languages/eslint.config.js;
    # Python LSP
    ".config/basedpyright/basedpyright.json".source = ../configs/languages/basedpyright.json;
    # Markdown LSP
    ".config/marksman/marksman.toml".source = ../configs/languages/marksman.toml;

    # --- Formatting & Linting Tools ----------------------------------------
    # Universal formatting
    ".editorconfig".source = ../configs/formatting/.editorconfig;
    ".prettierrc".source = ../configs/formatting/.prettierrc;
    # Python linting/formatting
    ".ruff.toml".source = ../configs/languages/ruff.toml;
    # Rust formatting, linting and LSP
    ".config/rust-analyzer/rust-analyzer.json".source = ../configs/languages/rust-analyzer.json;
    ".rustfmt.toml".source = ../configs/languages/rustfmt.toml;
    ".config/clippy/clippy.toml".source = ../configs/languages/clippy.toml;
    ".cargo-deny.toml".source = ../configs/languages/cargo-deny.toml;
    # Lua formatting
    ".stylua.toml".source = ../configs/languages/.stylua.toml;
    # Shell tools
    ".config/shellcheck/shellcheckrc".source = ../configs/languages/shellcheckrc;
    # TOML formatting
    ".taplo.toml".source = ../configs/formatting/.taplo.toml;
    # YAML formatting and linting
    ".yamllint.yml".source = ../configs/formatting/.yamllint.yml;
    ".yamlfmt".source = ../configs/formatting/.yamlfmt;

    # --- Development Tool Configurations -----------------------------------
    # Docker
    ".dockerignore".source = ../configs/apps/.dockerignore;

    # Package managers
    ".config/npm/npmrc".source = ../configs/npmrc;
    ".config/cargo/config.toml".source = ../configs/languages/cargo.toml;
    ".config/pypoetry/config.toml".source = ../configs/poetry.toml;
  };
}
