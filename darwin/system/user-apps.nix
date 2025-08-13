# Title         : user-apps.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/system/user-apps.nix
# ---------------------------------------
# User application preferences via CustomUserPreferences
{ myLib, ... }:

{
  system.defaults.CustomUserPreferences = {
    # --- Spotlight & Search ----------------------------------------------------
    "com.apple.spotlight" = {
      orderedItems = myLib.default [
        {
          enabled = true;
          name = "APPLICATIONS";
        }
        {
          enabled = true;
          name = "SYSTEM_PREFS";
        }
        {
          enabled = true;
          name = "DIRECTORIES";
        }
        {
          enabled = true;
          name = "PDF";
        }
        {
          enabled = true;
          name = "DOCUMENTS";
        }
        {
          enabled = false;
          name = "MESSAGES";
        }
        {
          enabled = false;
          name = "CONTACT";
        }
        {
          enabled = false;
          name = "EVENT_TODO";
        }
        {
          enabled = false;
          name = "IMAGES";
        }
        {
          enabled = false;
          name = "BOOKMARKS";
        }
        {
          enabled = false;
          name = "MUSIC";
        }
        {
          enabled = false;
          name = "MOVIES";
        }
        {
          enabled = false;
          name = "PRESENTATIONS";
        }
        {
          enabled = false;
          name = "SPREADSHEETS";
        }
        {
          enabled = false;
          name = "SOURCE";
        }
        {
          enabled = false;
          name = "MENU_DEFINITION";
        }
        {
          enabled = false;
          name = "MENU_OTHER";
        }
        {
          enabled = false;
          name = "MENU_CONVERSION";
        }
        {
          enabled = false;
          name = "MENU_EXPRESSION";
        }
        {
          enabled = false;
          name = "MENU_WEBSEARCH";
        }
        {
          enabled = false;
          name = "MENU_SPOTLIGHT_SUGGESTIONS";
        }
      ];
    };

    # --- Finder Extended Settings (not in system.defaults.finder) -------------
    "com.apple.finder" = {
      AppleShowAllFiles = myLib.default false; # Show hidden files
      _FXSortFoldersFirst = myLib.default true; # Folders at top in all views
      _FXSortFoldersFirstOnDesktop = myLib.default false; # Folders first on desktop
      DisableAllAnimations = myLib.default false; # Disable Finder animations
      WarnOnEmptyTrash = myLib.default true; # Warn when emptying trash
    };

    # --- Quick Look ------------------------------------------------------------
    "com.apple.finder.qlcache" = {
      enableTextSelection = myLib.default true; # Select text in Quick Look
    };

    # --- Safari (commented out -------------------------------------------------
    "com.apple.Safari" = {
      # AutoFillFromAddressBook = false;
      # AutoFillPasswords = false;
      # AutoOpenSafeDownloads = false;
      # IncludeDevelopMenu = true;
      # ShowFullURLInSmartSearchField = true;
      # SuppressSearchSuggestions = true;
    };

    # --- Third-Party App Configuration Templates ------------------------------
    # CleanShotX integration (placeholder for future discovery)
    # "pl.maketheweb.cleanshotx" = {
    #   # Settings to be discovered via `defaults read pl.maketheweb.cleanshotx`
    #   # after CleanShotX is installed and configured
    # };

    # Example: VSCode (Can configure via nix-darwin instead of settings.json)
    # "com.microsoft.VSCode" = {
    #   ApplePressAndHoldEnabled = false;
    #   AppleShowScrollBars = "Always";
    # };

    # Example: Arc Browser
    # "company.thebrowser.Browser" = {
    #   # Settings to be discovered
    # };

    # Example: 1Password
    # "com.1password.1password" = {
    #   # Settings to be discovered
    # };

    # Framework for Future App Configurations
    # "com.company.appname" = {
    #   setting1 = value1;
    #   setting2 = value2;
    # };
  };
}
