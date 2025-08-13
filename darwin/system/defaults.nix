# Title         : defaults.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/system/defaults.nix
# ---------------------------------------
# Main system defaults entry point - imports all system preference modules
{
  config,
  lib,
  ...
}:

{
  # --- Module Imports ---------------------------------------------------------
  imports = [
    ./global.nix # NSGlobalDomain settings
    ./dock.nix # Dock configuration
    ./finder.nix # Finder preferences
    ./trackpad.nix # Trackpad settings
    ./security.nix # Security: screensaver, login, firewall, Launch Services
    ./window-management.nix # Window management: Spaces, Stage Manager, tiling
    ./accessibility.nix # Accessibility: Universal Access, Fn keys, Magic Mouse
    ./system-apps.nix # System apps: Activity Monitor, Control Center, Clock, etc.
    ./user-apps.nix # User app preferences via CustomUserPreferences
    ./media.nix # Media: screenshots and related settings
  ];

  # --- Activation Script for Immediate Application ---------------------------
  # Apply settings immediately without logout/restart
  # Note: postUserActivation has been removed in newer nix-darwin versions
  # The activateSettings command should be handled by the system defaults framework itself

  # --- System Assertions ------------------------------------------------------
  # Validate that critical system components are properly configured
  assertions = [
    {
      assertion = config.system ? defaults;
      message = "System defaults configuration is required but not found";
    }
    {
      assertion = config.system.defaults ? NSGlobalDomain;
      message = "NSGlobalDomain configuration is required for proper system behavior";
    }
  ];

  # --- Warnings for User Awareness -------------------------------------------
  warnings =
    lib.optionals (config.system.defaults.dock.persistent-apps == [ ]) [
      "Dock persistent-apps is empty - add your preferred applications to darwin/system/dock.nix"
    ]
    ++ lib.optionals (!config.system.defaults.NSGlobalDomain.AppleShowAllExtensions) [
      "File extensions are hidden - consider enabling for better file management"
    ];
}
