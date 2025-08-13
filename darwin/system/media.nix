# Title         : media.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/system/media.nix
# ---------------------------------------
# Media and screenshot configurations
{ myLib, ... }:

{
  system.defaults = {
    # --- Screenshot Settings -------------------------------------------------
    screencapture = {
      location = myLib.default "~/Pictures/Screenshots"; # Screenshot save location
      type = myLib.default "png"; # File format: png/jpg/pdf
      disable-shadow = myLib.default false; # Include window shadows
      include-date = myLib.default true; # Add timestamp to filename
      show-thumbnail = myLib.default true; # Show preview thumbnail
      target = myLib.default "file"; # Destination: file/clipboard/preview/mail/messages
    };

    # --- Custom User Preferences for Media Apps -----------------------------
    CustomUserPreferences = {
      # Screen Recording & Privacy
      "com.apple.screensharing" = {
        privacyWarningShown = myLib.default null;
      };

      # Future media app configurations can be added here
      # Example: CleanShotX when configured
      # "pl.maketheweb.cleanshotx" = {
      #   # Settings discovered via `defaults read pl.maketheweb.cleanshotx`
      # };
    };
  };
}