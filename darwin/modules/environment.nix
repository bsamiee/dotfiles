# Title         : environment.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/modules/environment.nix
# ---------------------------------------
# Consolidated system-wide environment variables
# These are available to ALL users and GUI applications
{
  lib,
  userConfig,
  system,
  ...
}:

{
  # --- System-Wide Environment Variables ---------------------------------------
  environment.variables = {
    # --- Cache Configuration ---------------------------------------------------
    CACHIX_CACHE = userConfig.username;

    # --- macOS PATH Integration -------------------------------------------------
    # Ensure proper PATH construction for Intel Macs (Apple Silicon uses /opt/homebrew)
    PATH = lib.mkIf (system == "x86_64-darwin") (
      lib.mkBefore "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    );

    # --- System Integration ----------------------------------------------------
    # Additional system-wide variables can be added here as needed
  };
}
