# Title         : global.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/system/global.nix
# ---------------------------------------
# NSGlobalDomain settings - system-wide macOS preferences
{ myLib, ... }:

{
  system.defaults.NSGlobalDomain = {
    # --- Interface & Appearance -------------------------------------------------
    AppleInterfaceStyle = myLib.default "Dark"; # Dark mode
    AppleInterfaceStyleSwitchesAutomatically = myLib.default false; # Auto light/dark switching
    AppleShowScrollBars = myLib.default "WhenScrolling"; # Always/WhenScrolling/Automatic
    AppleScrollerPagingBehavior = myLib.default false; # Jump to spot clicked vs next page
    AppleFontSmoothing = myLib.default 2; # Font smoothing level (0=off, 1=light, 2=strong)

    # --- Keyboard & Input -------------------------------------------------------
    AppleKeyboardUIMode = myLib.default 3; # Full keyboard navigation (tab through all controls)
    ApplePressAndHoldEnabled = myLib.default false; # Disable accents popup, enable key repeat
    InitialKeyRepeat = myLib.default 15; # Delay until key repeat (lower=faster)
    KeyRepeat = myLib.default 2; # Key repeat rate (lower=faster)
    "com.apple.keyboard.fnState" = myLib.default true; # Use F1, F2, etc. as standard function keys

    # Text corrections (all disabled for power users)
    NSAutomaticCapitalizationEnabled = myLib.default false;
    NSAutomaticSpellingCorrectionEnabled = myLib.default false;
    NSAutomaticPeriodSubstitutionEnabled = myLib.default false;
    NSAutomaticQuoteSubstitutionEnabled = myLib.default false;
    NSAutomaticDashSubstitutionEnabled = myLib.default false;
    NSAutomaticInlinePredictionEnabled = myLib.default false;

    # --- Window & Navigation ----------------------------------------------------
    AppleWindowTabbingMode = myLib.default "fullscreen"; # always/manual/fullscreen
    NSNavPanelExpandedStateForSaveMode = myLib.default true; # Expanded save dialogs
    NSNavPanelExpandedStateForSaveMode2 = myLib.default true;
    NSDocumentSaveNewDocumentsToCloud = myLib.default false; # Save locally by default
    NSTableViewDefaultSizeMode = myLib.default 2; # Sidebar icon size
    NSWindowResizeTime = myLib.default 0.001; # Faster window resize animations
    NSWindowShouldDragOnGesture = myLib.default true; # Drag windows from anywhere with Cmd+Ctrl
    NSAutomaticWindowAnimationsEnabled = myLib.default true; # Window animations
    NSUseAnimatedFocusRing = myLib.default false; # Animated focus ring
    NSScrollAnimationEnabled = myLib.default true; # Smooth scrolling

    # --- Mouse & Trackpad -------------------------------------------------------
    "com.apple.mouse.tapBehavior" = myLib.default null; # Tap to click
    "com.apple.swipescrolldirection" = myLib.default true; # Natural scrolling
    "com.apple.trackpad.enableSecondaryClick" = myLib.default true;
    "com.apple.trackpad.trackpadCornerClickBehavior" = myLib.default null;
    "com.apple.trackpad.scaling" = myLib.default null; # Tracking speed
    AppleEnableMouseSwipeNavigateWithScrolls = myLib.default false; # Swipe between pages
    AppleEnableSwipeNavigateWithScrolls = myLib.default false;

    # --- Sound & Feedback -------------------------------------------------------
    "com.apple.sound.beep.volume" = myLib.default null; # Alert sound volume
    "com.apple.sound.beep.feedback" = myLib.default null; # Sound when changing volume

    # --- File Extensions & Saving ----------------------------------------------
    AppleShowAllExtensions = myLib.default true; # Always show file extensions
    AppleShowAllFiles = myLib.default false; # Show hidden files everywhere
    NSDisableAutomaticTermination = myLib.default false; # Apps stay open when windows close
    NSTextShowsControlCharacters = myLib.default false; # Show control characters in text

    # --- Spring Loading ---------------------------------------------------------
    "com.apple.springing.enabled" = myLib.default true; # Spring loading for directories
    "com.apple.springing.delay" = myLib.default 0.5; # Spring loading delay

    # --- Spaces & Mission Control ----------------------------------------------
    AppleSpacesSwitchOnActivate = myLib.default true; # Switch to space with open windows for app
  };
}
