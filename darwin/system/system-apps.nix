# Title         : system-apps.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/system/system-apps.nix
# ---------------------------------------
# System application configurations: Activity Monitor, Control Center, Clock, Software Update, SMB
{ myLib, ... }:

{
  system.defaults = {
    # --- Activity Monitor ----------------------------------------------------
    ActivityMonitor = {
      ShowCategory = myLib.default 100; # 100=All, 102=My, 103=System, 105=Active
      IconType = myLib.default 5; # 0=App Icon, 2=Network, 3=Disk, 5=CPU, 6=CPU History
      SortColumn = myLib.default "CPUUsage"; # Column to sort by
      SortDirection = myLib.default 0; # 0=descending
      OpenMainWindow = myLib.default true; # Open main window on launch
    };

    # --- Control Center ------------------------------------------------------
    controlcenter = {
      BatteryShowPercentage = myLib.default true; # Battery percentage in menu bar
      Sound = myLib.default true; # Show in menu bar
      Bluetooth = myLib.default true; # Show in menu bar
      AirDrop = myLib.default true; # Show in menu bar
      Display = myLib.default true; # Show brightness control in menu bar
      FocusModes = myLib.default true; # Show in menu bar
      NowPlaying = myLib.default true; # Show in menu bar
    };

    # --- Menu Bar Clock ------------------------------------------------------
    menuExtraClock = {
      FlashDateSeparators = myLib.default false; # Flash the : separator
      IsAnalog = myLib.default false; # Digital clock
      Show24Hour = myLib.default false; # 12-hour format
      ShowAMPM = myLib.default true; # Show AM/PM
      ShowDayOfMonth = myLib.default true; # Show day number
      ShowDayOfWeek = myLib.default true; # Show day name
      ShowDate = myLib.default 1; # 0=when space allows, 1=always, 2=never
      ShowSeconds = myLib.default false; # Don't show seconds
    };

    # --- Software Update -----------------------------------------------------
    SoftwareUpdate = {
      AutomaticallyInstallMacOSUpdates = myLib.default false; # Manual control over updates
    };

    # --- SMB/NetBIOS Settings ------------------------------------------------
    smb = {
      NetBIOSName = myLib.default null; # Use default hostname
      ServerDescription = myLib.default null; # Use default description
    };

    # --- Custom User Preferences for System Apps ----------------------------
    CustomUserPreferences = {
      # Desktop Services (File Operations)
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = myLib.default true; # No .DS_Store on network volumes
        DSDontWriteUSBStores = myLib.default true; # No .DS_Store on USB drives
        DSDontWriteISOStores = myLib.default true; # No .DS_Store on ISO images
      };

      # Time Machine
      "com.apple.TimeMachine" = {
        DoNotOfferNewDisksForBackup = myLib.default true; # Don't prompt for new backup disks
        AutoBackup = myLib.default null; # Auto backup enabled/disabled
        BackupSkipPaths = myLib.default null; # Paths to exclude from backup
      };

      # Telemetry & Privacy
      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = myLib.default false;
      };

      "com.apple.assistant.support" = {
        "Assistant Enabled" = myLib.default false; # Disable Siri
      };

      # Security & System Integrity
      "com.apple.security.libraryvalidation" = {
        DisableLibraryValidation = myLib.default false; # Keep library validation for security
      };

      # Network & Sharing
      "com.apple.NetworkBrowser" = {
        DisableAirDrop = myLib.default false; # Keep AirDrop enabled
        BrowseAllInterfaces = myLib.default true;
      };

      # Printing & Paper Handling
      "com.apple.print.PrintingPrefs" = {
        "Quit When Finished" = myLib.default true; # Quit printer app when done
      };

      # Archive Utility
      "com.apple.archiveutility" = {
        dearchive-reveal-after = myLib.default true; # Show extracted files in Finder
        archive-reveal-after = myLib.default true; # Show created archives in Finder
      };

      # Additional System UI Settings
      ".GlobalPreferences" = {
        AppleAccentColor = myLib.default null; # System accent color (0-6, null=default)
        AppleHighlightColor = myLib.default null; # Selection highlight color
        AppleReduceDesktopTinting = myLib.default false; # Less wallpaper tinting
        AppleActionOnDoubleClick = myLib.default "Maximize"; # Maximize/Minimize
        AppleMiniaturizeOnDoubleClick = myLib.default false; # Double-click title bar
        NSQuitAlwaysKeepsWindows = myLib.default false; # Restore windows on reopen
        AppleShowHelpOnHover = myLib.default true; # Show help tags on hover
        WebAutomaticSpellingCorrectionEnabled = myLib.default false;
        AppleMenuBarVisibleInFullscreen = myLib.default true; # Menu bar in fullscreen
        _HIHideMenuBar = myLib.default false; # Auto-hide menu bar
        NSStatusItemSelectionPadding = myLib.default null; # Menu bar item spacing
        NSStatusItemSpacing = myLib.default null; # Menu bar item spacing
        AppleMeasurementUnits = myLib.default "Inches"; # Inches/Centimeters
        AppleMetricUnits = myLib.default 0; # 0=Imperial, 1=Metric
        AppleTemperatureUnit = myLib.default "Fahrenheit"; # Celsius/Fahrenheit
        AppleICUForce24HourTime = myLib.default false; # Force 24-hour time
        AppleLocale = myLib.default null; # System locale
        AppleLanguages = myLib.default null; # Preferred languages
        NSLinguisticDataAssetsRequested = myLib.default null; # Downloaded languages
        NSToolbarTitleViewRolloverDelay = myLib.default 0.5; # Toolbar title hover
        NSAlertMetricsGatheringEnabled = myLib.default false; # Disable metrics
        NSAutomaticTextCompletionEnabled = myLib.default false; # Text completion
        "com.apple.sound.uiaudio.enabled" = myLib.default null; # UI sound effects
      };
    };
  };
}
