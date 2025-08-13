# Title         : fonts.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/modules/fonts.nix
# ---------------------------------------
# System font installation and configuration

{
  pkgs,
  lib,
  userConfig,
  ...
}:

let
  # Import our helper libraries
  darwinLib = import ../../lib/darwin.nix { inherit lib pkgs userConfig; };
in
{
  # --- Font Packages ------------------------------------------------------------
  # Enable system-wide font installation
  fonts = {
    # Note: fonts.packages is the new name (fonts.fonts is deprecated)
    packages = with pkgs; [
      # Primary programming and development fonts
      geist-font
      jetbrains-mono
      # Nerd Fonts for terminal and development
      # Using new individual package structure (post Nov 2024)
      nerd-fonts.jetbrains-mono
      nerd-fonts.meslo-lg
      nerd-fonts.fira-code
      nerd-fonts.hack
      # System and UI fonts
      inter
      source-sans-pro
      source-serif-pro
      source-code-pro
      # Additional utility fonts
      font-awesome
      material-design-icons
      # International and emoji support
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      # Classic and fallback fonts
      dejavu_fonts
      liberation_ttf
    ];
  };
  # --- Activation Scripts -------------------------------------------------------
  # System activation script for font management (macOS 15+ compatible)
  system.activationScripts.fonts = darwinLib.mkActivationScript "fonts" "modern font management" ''
    if [ -d "/Library/Fonts/Nix Fonts" ]; then
      chmod -R 644 "/Library/Fonts/Nix Fonts"/*.{ttf,otf,ttc} 2>/dev/null || true
      chmod 755 "/Library/Fonts/Nix Fonts"
    fi

    # Modern font cache management with macOS version detection
    MACOS_VERSION=$(sw_vers -productVersion | cut -d. -f1)

    if [[ $MACOS_VERSION -ge 15 ]]; then
      # macOS 15+ (Sequoia and later) uses new font registration system
      echo "Detected macOS 15+, using modern font registration..."
      /usr/bin/fontrestore default -n 2>/dev/null || true

      # Still clear user font cache for consistency
      atsutil databases -removeUser 2>/dev/null || true
    else
      # Legacy font cache clearing for macOS 14 and earlier
      echo "Using legacy font cache management..."
      /System/Library/Frameworks/ApplicationServices.framework/Frameworks/ATS.framework/Support/atsutil databases -remove 2>/dev/null || true
      /System/Library/Frameworks/ApplicationServices.framework/Frameworks/ATS.framework/Support/atsutil server -shutdown 2>/dev/null || true
      /System/Library/Frameworks/ApplicationServices.framework/Frameworks/ATS.framework/Support/atsutil server -ping 2>/dev/null || true
    fi

    # Clear user font cache and restart font server
    atsutil databases -removeUser 2>/dev/null || true
    atsutil server -shutdown 2>/dev/null || true
    atsutil server -ping 2>/dev/null || true

    echo "Font management configured with macOS $MACOS_VERSION compatibility"
  '';
}
