# Title         : consolidated-core.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/aliases/consolidated-core.nix
# ---------------------------------------
# TEMPORARY CONSOLIDATION FILE: All aliases for tools in core.nix
# This file will be used to organize and refine aliases before redistribution
_:

{
  aliases = {
    # ============================================================================
    # FILE & DIRECTORY OPERATIONS (eza, fd, broot, trash-cli, fcp, rsync)
    # ============================================================================

    # --- Core Unix Command Replacements ---
    # These override standard Unix commands with modern alternatives
    ls = "eza --icons=auto --group-directories-first";
    ll = "eza -la --icons=auto --group-directories-first --git";
    lt = "eza --tree --level=2 --icons=auto";
    ltr = "eza -l --sort=modified"; # Show oldest files first (most recent at bottom)

    find = "fd";
    tree = "eza --tree";
    cat = "bat";
    grep = "rg";

    # Safety and performance replacements
    rm = "trash-put"; # Safe deletion to trash
    cp = "fcp"; # Fast parallel copy
    mkdir = "mkdir -p"; # Always create parent directories
    mv = "mv -i"; # Interactive by default for safety

    # --- Trash Management ---
    trash = "trash-put"; # Explicit trash command
    trash-list = "trash-list"; # List trashed items
    trash-restore = "trash-restore"; # Recover from trash
    trash-empty = "trash-empty"; # Empty trash

    # --- Interactive File Operations ---
    br = "broot"; # Interactive file explorer

    # --- Quick Filters ---
    recent = "fd --changed-within 24h --type f"; # Files from last 24h
    old = "fd --changed-before 30d --type f"; # Files older than 30 days

    # --- Sync Operations ---
    sync = "rsync -avP"; # Progress, archive, verbose
    backup = "rsync -avP --delete"; # Mirror with deletion

    # ============================================================================
    # TEXT PROCESSING & SEARCH (bat, ripgrep, sd, xsv, choose, grex)
    # ============================================================================

    # --- bat (cat replacement) - FROM core.nix ---
    # cat = "bat";  # Already defined above

    # --- ripgrep (grep replacement) - FROM core.nix ---
    # grep = "rg";  # Already defined above

    # --- sd (sed replacement) - NEW ---
    # sed = "sd";  # Consider adding

    # --- xsv (CSV processor) - NEW ---
    # csv = "xsv";  # Consider adding

    # --- choose (column selector) - NEW ---
    # col = "choose";  # Consider adding

    # --- grex (regex generator) - NEW ---
    # regex = "grex";  # Consider adding

    # ============================================================================
    # FILE ANALYSIS & DIFF (delta, hexyl, tokei, file)
    # ============================================================================

    # --- delta (diff replacement) - NEW ---
    # diff = "delta";  # Consider adding

    # --- hexyl (hexdump replacement) - NEW ---
    # hex = "hexyl";  # Consider adding

    # --- tokei (cloc replacement) - NEW ---
    # cloc = "tokei";  # Consider adding

    # --- file (enhanced) - No specific aliases needed ---

    # ============================================================================
    # SYSTEM MONITORING (procs, bottom, duf, dust)
    # ============================================================================

    # --- procs (ps replacement) - FROM sysadmin.nix ---
    ps = "ps aux"; # Should be: procs
    psg = "ps aux | grep -v grep | grep -i"; # Should be: procs --tree
    pm = "ps aux --sort=-%mem | head -20"; # Should be: procs --sortd mem
    pc = "ps aux --sort=-%cpu | head -20"; # Should be: procs --sortd cpu

    # --- bottom (top replacement) - FROM core.nix TODO ---
    # top = "btm";  # TODO: Currently commented out in core.nix

    # --- duf (df replacement) - FROM sysadmin.nix ---
    df = "df -h"; # Should be: duf

    # --- dust (du replacement) - FROM sysadmin.nix ---
    dus = "du -sh * | sort -h"; # Should be: dust
    duf = "du -sh ."; # Should be: dust .

    # ============================================================================
    # NETWORK TOOLS (xh, openssh, doggo, gping, mtr)
    # ============================================================================

    # --- xh (curl/wget replacement) - FROM sysadmin.nix ---
    myip = "curl -s https://ipinfo.io/ip"; # Should be: xh ipinfo.io/ip
    speedtest = "curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -"; # Should use speedtest-cli

    # --- openssh - Standard, no changes needed ---

    # --- doggo (dig replacement) - FROM core.nix TODO ---
    # dig = "doggo";  # TODO: Currently commented out in core.nix

    # --- gping (ping with graphs) - FROM core.nix TODO ---
    ping = "ping -c 5"; # Should be: gping when ready

    # --- mtr (traceroute+ping) - NEW ---
    # traceroute = "mtr";  # Consider adding

    # ============================================================================
    # NETWORK ANALYSIS (bandwhich, iperf, nmap, whois, speedtest-cli)
    # ============================================================================

    # --- bandwhich - NEW ---
    # bandwidth = "sudo bandwhich";  # Consider adding

    # --- iperf - NEW ---
    # perf = "iperf3";  # Consider adding

    # --- nmap - FROM sysadmin.nix ---
    ports = "lsof -iTCP -sTCP:LISTEN -n -P"; # Could augment with nmap
    port = "lsof -i"; # Could augment with nmap

    # --- whois - Standard tool, no alias needed ---

    # --- speedtest-cli - NEW ---
    # speed = "speedtest-cli";  # Consider adding

    # ============================================================================
    # SHELL ENHANCEMENTS (zoxide, starship, direnv, fzf, vivid, mcfly)
    # ============================================================================

    # --- zoxide (cd replacement) - NEW ---
    # cd = "z";  # After zoxide init

    # --- starship - Configured via programs, no alias needed ---

    # --- direnv - Configured via programs, no alias needed ---

    # --- fzf - Used in functions, no direct alias needed ---

    # --- vivid - Used for LS_COLORS generation ---
    # lscolors = "vivid generate molokai";  # Consider adding

    # --- mcfly - Replaces ctrl+r, configured via init ---

    # ============================================================================
    # DEVELOPMENT TOOLS (just, hyperfine, jq, parallel, watchexec, tldr, ouch)
    # ============================================================================

    # --- just (make replacement) - NEW ---
    # make = "just";  # Consider adding

    # --- hyperfine (time replacement) - FROM core.nix ---
    time = "hyperfine";

    # --- jq (JSON processor) - FROM utilities.nix ---
    json = "jq .";
    jsonc = "jq -c .";
    jsons = "jq -S .";
    validate = "jq empty 2>/dev/null && echo '✓ Valid JSON' || echo '✗ Invalid JSON'";

    # --- parallel-full - NEW ---
    # parallel = "parallel";  # Standard name is fine

    # --- watchexec (watch replacement) - FROM utilities.nix ---
    watch = "watch -n 2"; # Should be: watchexec
    watchd = "watch -d -n 2"; # Should be: watchexec with diff

    # --- tldr (man replacement) - NEW ---
    # man = "tldr";  # Consider for common commands

    # --- ouch (tar/zip replacement) - FROM utilities.nix ---
    targz = "tar -czf"; # Should be: ouch compress
    tarls = "tar -tzf"; # Should be: ouch list
    extract = "extract.sh"; # Should be: ouch decompress

    # ============================================================================
    # PROGRAMS (neovim)
    # ============================================================================

    # --- neovim - FROM utilities.nix ---
    vi = "nvim";
    vim = "nvim";

    # ============================================================================
    # TERMINAL FILE MANAGERS (yazi, lf, ranger, nnn)
    # ============================================================================

    # --- Terminal file managers - NEW ---
    # fm = "yazi";  # Consider adding
    # lfm = "lf";  # Consider adding
    # rgr = "ranger";  # Consider adding
    # n3 = "nnn";  # Consider adding

    # ============================================================================
    # LEGACY/TO BE REPLACED
    # ============================================================================
    # These are current aliases that should be updated to use modern tools

    # FROM sysadmin.nix - Should use modern replacements
    big = "find . -type f -exec ls -lh {} + 2>/dev/null | sort -k5 -hr | head -20"; # Use: fd + dust

    # FROM sysadmin.nix - Network tools to update
    localip = "ipconfig getifaddr en0"; # Keep as is (macOS specific)
    flushdns = "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"; # Keep as is (macOS specific)

    # FROM sysadmin.nix - Process management to update
    k = "kill";
    k9 = "kill -9";
    kport = "lsof -ti:"; # Could enhance with procs
    zombie = "ps aux | awk '\$8 ~ /^Z/ { print \$2, \$11 }'"; # Use: procs --tree

    # FROM sysadmin.nix - System info to modernize
    topmem = "top -l 1 -o rsize -n 10"; # Use: btm
    topcpu = "top -l 1 -o cpu -n 10"; # Use: btm

    # FROM utilities.nix - Archive operations to modernize with ouch
    b64 = "base64";
    b64d = "base64 -d";

    # FROM utilities.nix - Text manipulation (some could use modern tools)
    lower = "tr '[:upper:]' '[:lower:]'";
    upper = "tr '[:lower:]' '[:upper:]'";
    trim = "awk '{$1=$1};1'";
    unique = "sort -u";
    count = "sort | uniq -c | sort -rn";
    cols = "column -t"; # Could use xsv for CSV

    # FROM utilities.nix - Quick calculations
    calc = "bc -l";
    hex = "printf '0x%x\\n'";
    dec = "printf '%d\\n'";

    # FROM utilities.nix - Environment
    envs = "env | sort";

    # FROM utilities.nix - File operations
    sizeof = "du -sh"; # Use: dust
    connections = "lsof -i -n -P | grep ESTABLISHED";
    openfiles = "lsof | wc -l";

    # FROM utilities.nix - Security
    genpass = "openssl rand -base64 32";
    gensecret = "openssl rand -hex 32";
    sha = "shasum -a 256";
    uuid = "uuidgen | tr '[:upper:]' '[:lower:]'";
  };
}
