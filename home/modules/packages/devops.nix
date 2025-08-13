# Title         : devops.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/modules/packages/devops.nix
# ---------------------------------------
# Development and DevOps tools (git, docker, build tools, cloud infrastructure)

{
  pkgs,
  lib,
  kubernetes,
  ...
}:

with pkgs;
[
  # --- Git Ecosystem Tools ------------------------------------------------------
  gh # GitHub's official command-line tool
  lazygit # Simple terminal UI for git commands
  gitAndTools.git-extras # Extra git commands (use git changelog instead of git-cliff)

  gitui # NEW TOOL ADDED - REPLACE LAZYGIT
  git-secret # NEW TOOL ADDED - PENDING CONFIGURATION - Encrypt secrets in git
  git-crypt # NEW TOOL ADDED - PENDING CONFIGURATION - Transparent file encryption in git
  gitleaks # NEW TOOL ADDED - PENDING CONFIGURATION - Secret scanner for git repos
  gitAndTools.bfg-repo-cleaner # NEW TOOL ADDED - PENDING CONFIGURATION - BFG Repo Cleaner
  restic # NEW TOOL ADDED - PENDING CONFIGURATION - Fast, secure backup program
  rclone # NEW TOOL ADDED - PENDING CONFIGURATION - Cloud storage sync

  # --- Container & Orchestration ------------------------------------------------
  docker-client # Docker CLI
  docker-compose # Docker Compose for multi-container apps
  colima # Container runtimes on macOS
  podman # NEW TOOL ADDED - PENDING CONFIGURATION - Docker alternative
  dive # NEW TOOL ADDED - PENDING CONFIGURATION - Docker image explorer
  lazydocker # NEW TOOL ADDED - PENDING CONFIGURATION - Docker TUI
  buildkit # NEW TOOL ADDED - PENDING CONFIGURATION - Next-gen container builder

  # --- Docker & Container Tools -------------------------------------------------
  hadolint # Dockerfile linter PENDING CONFIGURATION

  # --- Build Tools -------------------------------------------------------------
  cmake # Cross-platform build system
  pkg-config # Helper tool for compiling applications

  # --- Testing & Automation ----------------------------------------------------
  bats # Bash testing framework
  entr # File watcher for auto-running commands

  # --- Secret Management Tools --------------------------------------------------
  vault # NEW TOOL ADDED - PENDING CONFIGURATION - HashiCorp Vault
  pass # NEW TOOL ADDED - PENDING CONFIGURATION - Unix password manager
  gopass # NEW TOOL ADDED - PENDING CONFIGURATION - Pass on steroids
]
# --- Kubernetes Tools (Conditional) --------------------------------------------
++ lib.optionals kubernetes [
  # kubectl
  # k9s
  # helm
  # kubectx
]
