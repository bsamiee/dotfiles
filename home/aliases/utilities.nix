# Title         : utilities.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/shells/aliases/utilities.nix
# ---------------------------------------
# High-value utilities for power users - justified, consolidated, battle-tested
# Philosophy: Each alias earns its place through frequency of use and time saved
_:

{
  aliases = {
    # --- General Utilities ------------------------------------------------
    reload = "exec $SHELL";

    # --- Time & Date Operations -------------------------------------------
    now = "date +'%Y-%m-%d %H:%M:%S'"; # ISO 8601 timestamp
    today = "date +'%Y-%m-%d'"; # ISO date for filenames
    epoch = "date +%s"; # Unix timestamp (for scripts)
    week = "date +%V"; # Week number (sprint tracking)
    timestamp = "date +'%Y%m%d_%H%M%S'"; # Filename-safe timestamp

    # --- History & Command Recall ------------------------------------------
    h = "history"; # Show history
    hg = "history | rg"; # Search history (uses ripgrep)
    hist = "shell-analysis hist"; # Top 20 commands by frequency

    # --- JSON/YAML Processing ---------------------------------------------
    json = "jq ."; # Pretty print JSON
    jsonc = "jq -c ."; # Compact JSON (one line)
    jsons = "jq -S ."; # Sort keys in JSON
    y2j = "yq eval -o=json"; # YAML to JSON
    j2y = "yq eval -P"; # JSON to YAML
    validate = "jq empty 2>/dev/null && echo '✓ Valid JSON' || echo '✗ Invalid JSON'"; # JSON validation

    # --- HTTP Development Server ------------------------------------------
    serve = "f() { python3 -m http.server \${1:-8000}; }; f"; # Instant web server (usage: serve [port])

    # --- Archive Operations -----------------------------------------------
    # Universal archive handling via extract.sh script
    extract = "extract.sh"; # Smart extract/list any archive (usage: extract [--list] file)

    # Quick tar operations for common tasks
    targz = "tar -czf"; # Create tar.gz (usage: targz archive.tar.gz files...)
    tarls = "tar -tzf"; # List tar.gz contents

    # --- Encoding & Decoding ---------------------------------------------
    b64 = "base64"; # Base64 encode
    b64d = "base64 -d"; # Base64 decode
    urlencode = "shell-analysis.sh urlencode"; # URL encode
    urldecode = "shell-analysis.sh urldecode"; # URL decode

    # --- Text Manipulation -----------------------------------------------
    lower = "tr '[:upper:]' '[:lower:]'"; # Convert to lowercase
    upper = "tr '[:lower:]' '[:upper:]'"; # Convert to uppercase
    trim = "awk '{$1=$1};1'"; # Trim whitespace
    unique = "sort -u"; # Sort and deduplicate
    count = "sort | uniq -c | sort -rn"; # Count occurrences
    cols = "column -t"; # Align columns (great for CSV)

    # --- Environment & Configuration -------------------------------------
    envs = "env | sort"; # Sorted environment variables

    # --- Watch & Monitor -------------------------------------------------
    watch = "watch -n 2"; # Watch command every 2 seconds
    watchd = "watch -d -n 2"; # Watch with diff highlighting
    follow = "tail -f"; # Follow log file
    followg = "tail -f | rg"; # Follow and grep (usage: followg error log.txt)

    # --- Quick Navigation Helpers ----------------------------------------
    back = "cd \$OLDPWD"; # Return to previous directory (alternative to -)
    root = "cd \$(git rev-parse --show-toplevel 2>/dev/null || echo .)"; # Go to git root
    tmp = "cd \$(mktemp -d) && pwd"; # Create and enter temp directory

    # --- SSH & Remote Operations -----------------------------------------
    sshkey = "ssh-keygen -t ed25519 -C"; # Generate modern SSH key (usage: sshkey "email")
    sshcopy = "pbcopy < ~/.ssh/id_ed25519.pub && echo 'SSH key copied to clipboard'"; # Copy SSH key
    ssht = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"; # SSH without host checking (dev only!)

    # --- Performance & Diagnostics ---------------------------------------
    sizeof = "du -sh"; # Human-readable size
    connections = "lsof -i -n -P | grep ESTABLISHED"; # Active connections
    openfiles = "lsof | wc -l"; # Count open files (ulimit debugging)

    # --- Security & Secrets ----------------------------------------------
    genpass = "openssl rand -base64 32"; # Generate secure password
    gensecret = "openssl rand -hex 32"; # Generate hex secret
    sha = "shasum -a 256"; # SHA256 hash (for verification)
    uuid = "uuidgen | tr '[:upper:]' '[:lower:]'"; # Generate lowercase UUID

    # --- Quick Calculations ----------------------------------------------
    calc = "bc -l"; # Calculator with float support
    hex = "printf '0x%x\\n'"; # Decimal to hex
    dec = "printf '%d\\n'"; # Hex to decimal

    # --- Clipboard Integration -------------------------------------------
    # Already covered in macos.nix, but these are cross-platform versions
    # Only including for cross-platform support in future
    # clip = "pbcopy";                               # Copy to clipboard
    # unclip = "pbpaste";                            # Paste from clipboard

    # --- Editor/Terminal Launchers ----------------------------------------
    # Universal editor preferences (moved from launchers.nix)
    vi = "nvim"; # Use neovim for vi
    vim = "nvim"; # Use neovim for vim
    wez = "open -ga WezTerm"; # Launch WezTerm
  };
}
