# Title         : macos.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/modules/packages/macos.nix
# ---------------------------------------
# macOS-specific utilities and system tools

{ pkgs, ... }:

with pkgs;
[
  # --- macOS System Integration -------------------------------------------------
  mas # Mac App Store command-line interface
  _1password-cli # 1Password command-line tool

  # --- macOS Utilities ----------------------------------------------------------
  dockutil # Manage macOS dock items
  pngpaste # Paste PNG from clipboard
  duti # NEW TOOL ADDED - PENDING CONFIGURATION - Set default applications for document types
  switchaudio-osx # NEW TOOL ADDED - PENDING CONFIGURATION - Switch audio sources from CLI
  osx-cpu-temp # NEW TOOL ADDED - PENDING CONFIGURATION - Show CPU temperature

  # --- System Management --------------------------------------------------------
  m-cli # Swiss Army Knife for macOS
  trash-cli # Move files to trash instead of rm

]
