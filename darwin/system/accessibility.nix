# Title         : accessibility.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/system/accessibility.nix
# ---------------------------------------
# Accessibility and input assistance: Universal Access, Function keys, Magic Mouse
{ myLib, ... }:

{
  system.defaults = {
    # --- Universal Access ----------------------------------------------------
    universalaccess = {
      closeViewScrollWheelToggle = myLib.default false; # Zoom with scroll wheel
      closeViewZoomFollowsFocus = myLib.default false; # Zoom follows keyboard focus
      reduceMotion = myLib.default false; # Reduce animations
      reduceTransparency = myLib.default false; # Reduce window transparency
      mouseDriverCursorSize = myLib.default 1.0; # Normal cursor size
    };

    # --- Function Key Behavior -----------------------------------------------
    hitoolbox = {
      AppleFnUsageType = myLib.default "Do Nothing"; # Options: "Do Nothing", "Change Input Source", "Show Emoji & Symbols", "Start Dictation"
    };

    # --- Magic Mouse Settings ------------------------------------------------
    magicmouse = {
      MouseButtonMode = myLib.default "TwoButton"; # "OneButton" or "TwoButton" - allows right-click
    };
  };
}