# Title         : finder.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/system/finder.nix
# ---------------------------------------
# Finder configuration - valid Finder preferences only
{ myLib, ... }:

{
  system.defaults.finder = {
    # --- Desktop Settings -------------------------------------------------------
    CreateDesktop = myLib.default true; # Show items on desktop
    ShowExternalHardDrivesOnDesktop = myLib.default true; # External drives on desktop
    ShowHardDrivesOnDesktop = myLib.default false; # Internal drives on desktop
    ShowMountedServersOnDesktop = myLib.default true; # Network drives on desktop
    ShowRemovableMediaOnDesktop = myLib.default true; # USB/DVD on desktop

    # --- View Preferences -------------------------------------------------------
    FXDefaultSearchScope = myLib.default "SCcf"; # Search scope: SCcf=current folder, SCsp=previous scope, SCev=entire volume
    FXPreferredViewStyle = myLib.default "clmv"; # View style: clmv=column, Nlsv=list, icnv=icon, Flwv=gallery

    # --- File Operations --------------------------------------------------------
    FXEnableExtensionChangeWarning = myLib.default true; # Warn when changing file extension
    FXRemoveOldTrashItems = myLib.default null; # Auto-remove trash items after 30 days

    # --- Window Settings --------------------------------------------------------
    NewWindowTarget = myLib.default "Home"; # New window location: Home, Desktop, Documents, Other
    NewWindowTargetPath = myLib.default null; # Custom path if NewWindowTarget=Other
    ShowPathbar = myLib.default true; # Show path bar at bottom
    ShowStatusBar = myLib.default true; # Show status bar with item count/size
    _FXShowPosixPathInTitle = myLib.default false; # Show full POSIX path in window title

    # --- Advanced Features ------------------------------------------------------
    QuitMenuItem = myLib.default false; # Enable Cmd+Q to quit Finder
  };
}