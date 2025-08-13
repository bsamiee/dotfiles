# Title         : security.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/system/security.nix
# ---------------------------------------
# Security-related system settings: screensaver, login window, firewall, and Launch Services
{ myLib, ... }:

{
  system.defaults = {
    # --- Screensaver & Lock Screen ------------------------------------------
    screensaver = {
      askForPassword = myLib.default true; # Require password after screensaver
      askForPasswordDelay = myLib.default 5; # Delay in seconds before password required
    };

    # --- Login Window --------------------------------------------------------
    loginwindow = {
      # Display & Authentication
      SHOWFULLNAME = myLib.default false; # Show username/password fields vs user list
      GuestEnabled = myLib.default false; # Disable guest account
      LoginwindowText = myLib.default null; # Custom message on login screen

      # Power Controls
      ShutDownDisabled = myLib.default false; # Show shutdown button
      SleepDisabled = myLib.default false; # Show sleep button
      RestartDisabled = myLib.default false; # Show restart button
      ShutDownDisabledWhileLoggedIn = myLib.default false; # Allow shutdown when logged in
      PowerOffDisabledWhileLoggedIn = myLib.default false; # Allow power off when logged in
      RestartDisabledWhileLoggedIn = myLib.default false; # Allow restart when logged in

      # Security
      DisableConsoleAccess = myLib.default true; # Prevent console access at login
      autoLoginUser = myLib.default null; # No auto-login for security
    };

    # --- Application Layer Firewall (ALF) -----------------------------------
    # Note: alf options are deprecated in newer nix-darwin versions
    # Use networking.applicationFirewall instead (configured in darwin/modules/)

    # --- Launch Services -----------------------------------------------------
    LaunchServices = {
      LSQuarantine = myLib.default false; # Disable quarantine for smoother app experience
    };
  };
}
