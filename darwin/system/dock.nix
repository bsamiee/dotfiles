# Title         : dock.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/system/dock.nix
# ---------------------------------------
# Dock configuration - all available dock settings
{ myLib, userConfig, ... }:

{
  system.defaults.dock = {
    # --- Position & Size --------------------------------------------------------
    orientation = myLib.default "bottom"; # left/bottom/right
    tilesize = myLib.default 48; # Dock icon size (16-128)
    largesize = myLib.default 64; # Magnified icon size
    magnification = myLib.default false; # Enable magnification on hover

    # --- Behavior ---------------------------------------------------------------
    autohide = myLib.default false; # Auto-hide the dock
    autohide-delay = myLib.default 0.5; # Delay before showing (seconds)
    autohide-time-modifier = myLib.default 0.5; # Animation speed (0=instant, 1=slow)
    show-process-indicators = myLib.default true; # Show dots for running apps
    show-recents = myLib.default false; # Show recent apps in dock
    static-only = myLib.default false; # Only show running apps
    minimize-to-application = myLib.default false; # Minimize to app icon vs right side
    mineffect = myLib.default "genie"; # genie/scale/suck minimize effect
    launchanim = myLib.default true; # Animate opening applications

    # --- Mission Control --------------------------------------------------------
    expose-animation-duration = myLib.default 1.0; # Mission control animation speed
    expose-group-apps = myLib.default false; # Group windows by application
    mru-spaces = myLib.default true; # Auto-rearrange spaces based on use

    # --- Dashboard & Widgets ----------------------------------------------------
    dashboard-in-overlay = myLib.default true; # Dashboard as overlay vs space

    # --- Mouse & Gestures -------------------------------------------------------
    mouse-over-hilite-stack = myLib.default true; # Highlight stack items on hover
    showhidden = myLib.default false; # Dim hidden app icons

    # --- Persistent Apps --------------------------------------------------------
    # Basic system apps to prevent empty dock issues
    # Format: [ "/Applications/App.app" "/System/Applications/App.app" ]
    persistent-apps = myLib.default [
      "/System/Applications/Finder.app"
      "/System/Applications/System Settings.app"
    ];

    # --- Persistent Others (Folders) -------------------------------------------
    # Trash is included here as a special folder
    # Format: [ "/Users/username/Downloads" "/Users/username/Documents" ]
    persistent-others = myLib.default [
      "/Users/${userConfig.username}/.Trash"
    ];

    # --- Window Behaviors -------------------------------------------------------
    appswitcher-all-displays = myLib.default false; # Show app switcher on all displays
    enable-spring-load-actions-on-all-items = myLib.default false; # Spring loading

    # Note: Hot corners disabled per user request
    # wvous-tl-corner = 1;  # Top left corner action (1-14)
    # wvous-tr-corner = 1;  # Top right corner action
    # wvous-bl-corner = 1;  # Bottom left corner action
    # wvous-br-corner = 1;  # Bottom right corner action
    # wvous-tl-modifier = 0; # Modifier key for corner (0=none, 131072=Shift, etc)
  };
}