# Title         : macos.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/shells/aliases/macos.nix
# ---------------------------------------
# macOS-specific aliases - unique system features not covered elsewhere
_:

{
  aliases = {
    # Finder & navigation
    o = "open"; # Open file/URL with default app
    oo = "open ."; # Open current directory in Finder
    reveal = "open -R"; # Reveal file in Finder

    # Clipboard operations
    copy = "pbcopy"; # Pipe to clipboard
    paste = "pbpaste"; # Output clipboard contents
    clip = "screencapture -ic"; # Screenshot to clipboard

    # Quick Look preview
    preview = "qlmanage -p 2>/dev/null"; # Preview without opening app

    # Spotlight search (indexes file contents, not just names)
    search = "mdfind"; # Search everywhere via Spotlight
    searchhere = "mdfind -onlyin ."; # Search current dir via Spotlight

    # System power & display
    awake = "caffeinate -dims"; # Prevent sleep (Ctrl+C to stop)
    lock = "pmset displaysleepnow"; # Lock screen immediately

    # System information
    battery = "pmset -g batt"; # Battery status
    wifi = "networksetup -getairportnetwork en0"; # Current WiFi network

    # Finder settings
    hf = "defaults write com.apple.finder AppleShowAllFiles YES && killall Finder"; # Show hidden files
    hhf = "defaults write com.apple.finder AppleShowAllFiles NO && killall Finder"; # Hide hidden files

    # Trash management
    emptytrash = "rm -rf ~/.Trash/* ~/.Trash/.*"; # Empty trash completely
  };
}
