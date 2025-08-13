# Title         : trackpad.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/system/trackpad.nix
# ---------------------------------------
# Trackpad configuration - all available trackpad settings
{ myLib, ... }:

{
  system.defaults.trackpad = {
    # --- Click Settings ---------------------------------------------------------
    Clicking = myLib.default true; # Tap to click
    TrackpadRightClick = myLib.default true; # Two-finger right click

    # --- Force Touch Settings ---------------------------------------------------
    ActuationStrength = myLib.default 0; # Force click pressure (0=light, 1=medium, 2=firm)
    FirstClickThreshold = myLib.default 1; # Pressure for first click (0=light, 1=medium, 2=firm)
    SecondClickThreshold = myLib.default 1; # Pressure for force click (0=light, 1=medium, 2=firm)

    # --- Drag Settings ----------------------------------------------------------
    Dragging = myLib.default false; # Three-finger drag (deprecated, use TrackpadThreeFingerDrag)
    TrackpadThreeFingerDrag = myLib.default true; # Three-finger drag gesture

    # --- Gesture Settings -------------------------------------------------------
    TrackpadThreeFingerTapGesture = myLib.default 0; # Three-finger tap action
    # 0 = No action
    # 1 = Look up & data detectors
    # 2 = Tap with three fingers (configurable in System Preferences)
  };
}
