# Title         : fonts.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/modules/fonts.nix
# ---------------------------------------
_:

{
  # Enable fontconfig for font discovery and management, This allows user applications to find and use system-installed fonts
  fonts.fontconfig = {
    enable = true;
    # Font configuration settings
    defaultFonts = {
      # Use system-installed fonts as defaults
      serif = [
        "Source Serif Pro"
        "Noto Serif"
      ];
      sansSerif = [
        "Inter"
        "Source Sans Pro"
        "Noto Sans"
      ];
      monospace = [
        "JetBrains Mono"
        "Source Code Pro"
        "Noto Sans Mono"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
