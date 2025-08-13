# Title         : window-management.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/system/window-management.nix
# ---------------------------------------
# Window and space management: Mission Control, Spaces, Stage Manager, and tiling
{ myLib, ... }:

{
  system.defaults = {
    # --- Mission Control & Spaces -------------------------------------------
    spaces = {
      spans-displays = myLib.default false; # Each display has its own spaces
    };

    # --- Stage Manager & Window Tiling --------------------------------------
    WindowManager = {
      # Stage Manager
      GloballyEnabled = myLib.default false; # Enable Stage Manager
      EnableStandardClickToShowDesktop = myLib.default true; # Click wallpaper to show desktop
      AutoHide = myLib.default false; # Auto-hide Stage Manager strip
      AppWindowGroupingBehavior = myLib.default null; # Window grouping: "One at a time" or "All at once"
      StandardHideDesktopIcons = myLib.default false; # Hide desktop items normally
      HideDesktop = myLib.default false; # Hide desktop items in Stage Manager

      # Window Tiling (macOS 15+)
      EnableTilingByEdgeDrag = myLib.default true; # Drag to edges to tile
      EnableTopTilingByEdgeDrag = myLib.default true; # Drag to menu bar to fill screen
      EnableTilingOptionAccelerator = myLib.default true; # Hold Option to tile
      EnableTiledWindowMargins = myLib.default true; # Margins between tiled windows

      # Widgets
      StandardHideWidgets = myLib.default false; # Hide widgets on desktop
      StageManagerHideWidgets = myLib.default false; # Hide widgets in Stage Manager
    };
  };
}