# Title         : homebrew.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/modules/homebrew.nix
# ---------------------------------------
{
  myLib,
  ...
}:

{
  homebrew = {
    enable = myLib.default true;

    # --- Global Settings ----------------------------------------------------------
    global = {
      autoUpdate = myLib.default false;
      brewfile = myLib.default true;
      lockfiles = myLib.default true; # Lock file for reproducible Homebrew state
    };
    # --- Taps, Brews, and Casks -------------------------------------------------
    taps = myLib.default [
      "homebrew/services"
    ];
    # macOS-specific tools that need native integration
    brews = myLib.default [
      "terminal-notifier" # macOS notification system integration
      "mono" # .NET runtime (dependency for some tools)
      "codex" # AI coding assistant (proprietary, not in Nix)
    ];
    # GUI applications requiring macOS integration and Spotlight
    casks = myLib.default [
      "1password" # Password manager
      "wezterm@nightly" # Terminal emulator (nightly build)
      "dotnet-sdk" # .NET SDK (large, GUI tools)
      "font-jetbrains-mono-nerd-font" # Developer font with icons
      "font-meslo-lg-nerd-font" # Terminal font with icons
      "iina" # NEW TOOL ADDED - PENDING CONFIGURATION - Modern media player for macOS
      "cleanshot" # Advanced screenshot and screen recording tool
    ];
    # --- Activation & Cask Arguments ----------------------------------------------
    onActivation = {
      autoUpdate = myLib.default false;
      cleanup = myLib.default "zap";
      upgrade = myLib.default false;
      # Enhanced debugging and service management
      extraFlags = myLib.default [ "--verbose" ];
    };
    # Enhanced cask configuration for better app management
    caskArgs = myLib.default {
      appdir = "/Applications";
      require_sha = true; # Security: verify checksums
    };
  };
}
