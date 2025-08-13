# Title         : base.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/hosts/base.nix
# ---------------------------------------
# Base configuration shared across all machines
{
  userConfig,
  ...
}:

{
  # --- Module Imports -----------------------------------------------------------
  imports = [
    ../modules/settings.nix
    ../modules/environment.nix # Consolidated system-wide environment variables
    ../modules/cache.nix # Unified cache configuration
    ../modules/networking.nix # Network and firewall configuration
    ../modules/homebrew.nix
    ../system/defaults.nix # Comprehensive system defaults configuration
    ../modules/fonts.nix
    ../modules/file-management.nix
    ../modules/xdg.nix
  ];

  # --- System & User Configuration ----------------------------------------------
  system.stateVersion = 6;
  system.primaryUser = userConfig.username;

  # User configuration
  users.users.${userConfig.username} = {
    name = userConfig.username;
    home = userConfig.userHome;
  };

  # --- Program Configuration ----------------------------------------------------
  programs.zsh.enable = true;
}
