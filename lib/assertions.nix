# Title         : assertions.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : lib/assertions.nix
# ---------------------------------------
# System-wide assertions for dotfiles configuration validation
{
  lib,
  userConfig ? null,
  system ? null,
  myLib ? null,
  ...
}:

let
  inherit (lib) mkIf hasPrefix hasSuffix;

  # --- User Configuration Assertions --------------------------------------------
  systemAssertions = lib.optionals (userConfig != null) [
    # Validate user configuration
    {
      assertion = userConfig.username != null && userConfig.username != "";
      message = "username cannot be empty or null";
    }
    {
      assertion =
        builtins.match "^[a-zA-Z0-9._-]+$" userConfig.username != null
        && !hasPrefix "." userConfig.username
        && !hasSuffix "." userConfig.username;
      message = "Invalid username format: ${userConfig.username}. Username must contain only letters, numbers, dots, underscores, and hyphens, and cannot start or end with a dot.";
    }
    {
      assertion =
        builtins.match "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$" userConfig.gitEmail != null;
      message = "Invalid email format: ${userConfig.gitEmail}";
    }
    {
      assertion = hasPrefix "/" (toString userConfig.userHome);
      message = "userHome must be an absolute path, but got: ${userConfig.userHome}";
    }
    {
      assertion = hasPrefix "/" (toString userConfig.flakeRoot);
      message = "flakeRoot must be an absolute path, but got: ${userConfig.flakeRoot}";
    }
    # Validate paths exist (only if they should exist)
    {
      assertion = userConfig.userHome == "/Users/${userConfig.username}";
      message = "userHome (${userConfig.userHome}) should match username (${userConfig.username})";
    }
    # Validate git username is not empty and reasonable
    {
      assertion = userConfig.gitUsername != "" && builtins.stringLength userConfig.gitUsername <= 50;
      message = "gitUsername must be non-empty and under 50 characters, got: '${userConfig.gitUsername}'";
    }
  ];

in
{
  # --- System-level Assertions --------------------------------------------------
  assertions =
    systemAssertions
    ++ lib.optionals (system != null) [
      # Ensure nix-darwin is being used on macOS
      {
        assertion =
          if myLib != null then
            myLib.isDarwin system
          else
            system == "aarch64-darwin" || system == "x86_64-darwin";
        message = "This nix-darwin configuration can only be used on macOS (got: ${system})";
      }
      # Ensure minimum macOS version compatibility (macOS 12+)
      {
        assertion =
          # For now, we assume macOS is compatible if it's Darwin
          # Full version checking would require impure evaluation
          # which is not ideal for assertions
          if myLib != null then
            myLib.isDarwin system
          else
            system == "aarch64-darwin" || system == "x86_64-darwin";
        message = "This configuration requires macOS 12 (Monterey) or later. Please ensure your macOS is up to date.";
      }
      # Ensure flakeRoot is properly configured
      {
        assertion = userConfig.flakeRoot == "${userConfig.userHome}/.dotfiles";
        message = "flakeRoot should be at ~/.dotfiles but is at ${userConfig.flakeRoot}";
      }
      # Ensure we're not running as root
      {
        assertion = userConfig.username != "root";
        message = "This configuration should not be run as root user";
      }
    ];

  # --- System-level Warnings ----------------------------------------------------
  warnings = lib.optionals (userConfig != null) [
    # Warn if flake root is not in user home
    (mkIf (
      !hasPrefix userConfig.userHome userConfig.flakeRoot
    ) "flakeRoot (${userConfig.flakeRoot}) is not under userHome (${userConfig.userHome})")
    # Warn about potential issues
    (mkIf (
      userConfig.username == "root"
    ) "Using 'root' as username is not recommended for this configuration")
  ];
}
