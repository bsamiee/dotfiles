# Title         : ls.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : lib/modern-commands/commands/ls.nix
# ---------------------------------------
# Configuration for ls command replacement with eza

_:

{
  baseCommand = "eza";
  description = "Modern ls replacement using eza with smart defaults";

  # Default flags always applied
  defaultFlags = [
    "--icons=auto" # Show icons when terminal supports
    "--group-directories-first" # Directories at top
    "--color=auto" # Colors when terminal supports
    "--time-style=long-iso" # Consistent ISO timestamps
    "--no-quotes" # Cleaner filenames without escaping
  ];

  # Unix ls flag → eza flag mappings
  flagMappings = {
    # Sorting options
    "-t" = "--sort=modified"; # Sort by modification time
    "-S" = "--sort=size"; # Sort by size
    "-r" = "--reverse"; # Reverse sort order
    "-X" = "--sort=extension"; # Sort by extension
    "-U" = "--sort=none"; # Unsorted
    "-c" = "--sort=created"; # Sort by creation time
    "-u" = "--sort=accessed"; # Sort by access time

    # Display options
    "-R" = "--recurse"; # Recursive listing
    "-h" = "--binary"; # Human readable sizes
    "-H" = "--dereference"; # Follow command-line symlinks
    "-i" = "--inode"; # Show inode numbers
    "-s" = "--blocksize"; # Show file sizes in blocks
    "-k" = "--bytes"; # File sizes in kilobytes

    # Permission/ownership options
    "-g" = "--group"; # Show group ownership
    "-o" = "--octal-permissions"; # Show permissions in octal
    "-n" = "--numeric"; # Numeric uid/gid
    "-G" = "--no-group"; # Don't show group

    # Format options
    "-x" = "--across"; # List entries by lines instead of columns
    "-1" = "--oneline"; # One file per line
    "-m" = "--grid"; # Comma-separated (grid mode in eza)
    "-C" = "--grid"; # Multi-column (default in eza)

    # File type indicators
    "-F" = ""; # Classify (eza does this with icons)
    "-p" = ""; # Append / to directories (eza does this)

    # Note: -l, -a, -A, -d, -L are handled natively by eza
  };

  # Context-aware flag additions
  contextRules = [
    {
      # Git status in git repositories
      condition = "[[ -d .git ]] || git rev-parse --git-dir >/dev/null 2>&1";
      flags = [ "--git" ];
    }
    {
      # Disable icons and colors when output is piped
      condition = "! [[ -t 1 ]]";
      flags = [
        "--no-icons"
        "--color=never"
        "--no-quotes"
      ];
    }
    {
      # Add headers in long format when interactive
      condition = "[[ -t 1 ]] && [[ \"\${LS_LONG:-}\" == \"true\" ]]";
      flags = [ "--header" ];
    }
    {
      # Use extended attributes on macOS
      condition = "[[ $(uname) == 'Darwin' ]] && [[ -t 1 ]]";
      flags = [ "--extended" ];
    }
    {
      # Show mount points on macOS when in long format
      condition = "[[ $(uname) == 'Darwin' ]] && [[ \"\${LS_LONG:-}\" == \"true\" ]]";
      flags = [ "--mounts" ];
    }
    {
      # Use hyperlinks if terminal supports it
      condition = "[[ -n \"\${TERM_PROGRAM:-}\" ]] && [[ \"\${TERM_FEATURES:-}\" == *hyperlink* ]]";
      flags = [ "--hyperlink" ];
    }
    {
      # Use relative time in interactive mode
      condition = "[[ -t 1 ]] && [[ \"\${LS_TIME_STYLE:-}\" == \"relative\" ]]";
      flags = [ "--time-style=relative" ];
    }
  ];

  # Additional eza-specific features
  _modernFeatures = {
    # Git integration
    gitRepos = "--git-repos"; # Show git status for repos
    gitIgnore = "--git-ignore"; # Respect .gitignore

    # Display enhancements
    header = "--header"; # Add column headers
    hyperlink = "--hyperlink"; # Clickable file links
    classify = "--classify"; # File type indicators

    # Metadata display
    mounts = "--mounts"; # Show mount details
    context = "--context"; # SELinux context
    flags = "--flags"; # File flags (macOS/BSD)

    # Advanced sorting
    sortByName = "--sort=name"; # Case-sensitive name sort
    sortByNameInsensitive = "--sort=Name"; # Case-insensitive name sort (fixed duplicate key)

    # Time display styles
    timeDefault = "--time-style=default";
    timeIso = "--time-style=iso";
    timeLongIso = "--time-style=long-iso";
    timeFullIso = "--time-style=full-iso";
    timeRelative = "--time-style=relative";

    # Color scales for sizes/dates
    colorScale = "--color-scale";
    colorScaleMode = "--color-scale-mode";
  };
}
