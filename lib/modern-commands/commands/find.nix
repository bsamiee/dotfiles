# Title         : find.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : lib/modern-commands/commands/find.nix
# ---------------------------------------
# Configuration for find command replacement with fd

_:

{
  baseCommand = "fd";
  description = "Modern find replacement using fd with smart defaults";

  # Default flags for better UX while maintaining find compatibility
  defaultFlags = [
    # Use --unrestricted levels for better control:
    # -u: show hidden files
    # -uu: show hidden + ignored files
    # -uuu: show everything including .git
    "-u" # Show hidden files (like find's default)
    "--color=auto" # Add colors only when outputting to terminal
  ];

  # Unix find flag → fd flag mappings
  flagMappings = {
    # Search pattern options
    "-name" = "--glob"; # Use glob mode for shell patterns
    "-iname" = "--glob --ignore-case"; # Case-insensitive glob
    "-path" = "--full-path"; # Search full path not just filename
    "-regex" = ""; # fd uses regex by default
    "-iregex" = "--ignore-case"; # Case-insensitive regex

    # File type options (simplified - complex types handled in function)
    "-type" = "--type"; # Needs value translation

    # Depth control
    "-maxdepth" = "--max-depth"; # Maximum search depth
    "-mindepth" = "--min-depth"; # Minimum search depth
    "-depth" = ""; # fd does depth-first by default

    # Time-based filters (need value translation)
    "-mtime" = "--changed-within"; # Modification time
    "-ctime" = "--changed-within"; # Status change time (approx)
    "-newer" = "--newer"; # Newer than file
    "-newermt" = "--changed-within"; # Newer than date
    "-atime" = ""; # Access time not supported
    "-anewer" = ""; # Access time not supported

    # Size filters
    "-size" = "--size"; # File size (needs value translation)

    # Actions
    "-print" = ""; # Default behavior
    "-print0" = "--print0"; # Null-separated output
    "-exec" = "--exec"; # Execute command (needs syntax fix)
    "-execdir" = "--exec"; # fd exec is always relative
    "-delete" = ""; # Special handling needed
    "-ls" = "--list"; # Detailed listing format

    # Symlink handling
    "-L" = "--follow"; # Follow symlinks
    "-H" = "--follow"; # Approximate (follow args only)
    "-P" = ""; # Default (don't follow)

    # Other options
    "-empty" = "--type empty"; # Empty files/directories (correct syntax)
    "-executable" = "--type executable"; # Executable files
    "-xdev" = "--one-file-system"; # Don't cross filesystem boundaries
    "-mount" = "--one-file-system"; # Alias for -xdev

    # Options to exclude/prune
    "-prune" = "--exclude"; # Exclude paths
    "-not" = ""; # Needs special handling
    "!" = ""; # Needs special handling

    # Ownership filters (now supported in fd)
    "-user" = "--owner"; # Filter by user
    "-group" = "--owner"; # Filter by group
    "-uid" = "--owner"; # Filter by uid
    "-gid" = "--owner"; # Filter by gid
  };

  # Context-aware flag additions
  contextRules = [
    {
      # Disable colors when output is piped
      condition = "! [[ -t 1 ]]";
      flags = [ "--color=never" ];
    }
    {
      # Strip ./ prefix when not piping for cleaner output
      condition = "[[ -t 1 ]]";
      flags = [ "--strip-cwd-prefix" ];
    }
    {
      # Use fewer threads for small directories (performance optimization)
      condition = "[[ $(ls -1 2>/dev/null | wc -l) -lt 100 ]]";
      flags = [ "--threads=2" ];
    }
    {
      # Enable gitignore filtering if requested (opt-in enhancement)
      condition = "[[ -n \"\${FIND_RESPECT_GITIGNORE:-}\" ]]";
      flags = [ "--ignore-vcs" ]; # This overrides the -u flag
    }
    {
      # Full unrestricted mode (show everything including .git)
      condition = "[[ \"\${FIND_UNRESTRICTED:-}\" == \"full\" ]]";
      flags = [ "-uuu" ]; # Show everything
    }
    {
      # Strict compatibility mode
      condition = "[[ \"\${FIND_COMPAT:-}\" == \"strict\" ]]";
      flags = [
        "--color=never"
        "-uu"
      ]; # No colors, show hidden+ignored
    }
  ];

  # Special handlers for complex translations
  specialHandlers = {
    # Handle -type with multiple values (e.g., -type f,d)
    typeHandler = true;

    # Translate time values (-7 → 7d, +7 → >7d)
    timeHandler = true;

    # Translate size values (+10M → >10M, -10M → <10M)
    sizeHandler = true;

    # Handle -exec syntax differences
    execHandler = true;

    # Handle logical operators (!, -not, -a, -o)
    logicalHandler = true;

    # Handle -delete action safely
    deleteHandler = true;

    # Handle file extensions smartly
    extensionHandler = true;

    # Handle --format for custom output
    formatHandler = true;
  };

  # Additional fd-specific features
  modernFeatures = {
    # File extension filtering (more intuitive than -name)
    extension = "--extension"; # -e shorthand available

    # Exclude patterns
    exclude = "--exclude"; # -E shorthand available

    # Time filtering for older files
    changedBefore = "--changed-before";

    # Custom output formatting
    format = "--format"; # e.g., {//} for dirname, {.} for stem

    # Hyperlink support for modern terminals
    hyperlink = "--hyperlink";

    # Batch size for exec operations
    batchSize = "--batch-size";

    # Maximum results
    maxResults = "--max-results";

    # Base directory
    baseDirectory = "--base-directory";
  };

  # Unsupported features with helpful messages
  unsupportedFeatures = {
    "-perm" = "Permission filtering not supported. Use: fd ... --exec test -perm {} \\;";
    "-atime" = "Access time filtering not supported. fd only supports modification time.";
    "-anewer" = "Access time comparison not supported. Use --changed-within or --changed-before.";
    "-links" = "Hard link count filtering not supported.";
    "-inum" = "Inode number filtering not supported.";
    "-samefile" = "Same file detection not supported.";
    "-ok" = "Interactive exec not supported. Use --exec with confirmation script.";
  };
}
