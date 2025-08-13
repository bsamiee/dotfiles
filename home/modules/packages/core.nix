# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/modules/packages/core.nix
# ---------------------------------------
# Modern CLI replacements for Unix commands and essential developer tools

{ pkgs, ... }:

with pkgs;
[
  # --- File & Directory Operations ----------------------------------------------
  eza # ls → Modern file listing with git integration, icons, tree view
  fd # find → Fast file finder respecting .gitignore
  broot # tree → Interactive file tree explorer
  trash-cli # rm → Safe deletion to trash instead of permanent delete
  fcp # cp → Fast parallel file copy (simple cases)
  # xcp # Linux-only: depends on acl package
  uutils-coreutils-noprefix # Full POSIX cp when fcp lacks features (-r, -p, -a, --reflink CoW)
  rsync # mv/sync → Advanced file synchronization and transfer

  # --- Text Processing & Search -------------------------------------------------
  bat # cat → Syntax highlighting viewer with line numbers
  ripgrep # grep → Ultra-fast text search (rg command)
  sd # sed → Intuitive find/replace without regex complexity
  xan # awk/cut → CSV/TSV data processor (xsv successor)
  choose # cut → Human-friendly column selector
  grex # → Generate regex patterns from examples

  # --- File Analysis & Diff -----------------------------------------------------
  delta # diff → Syntax-aware diff viewer with side-by-side view
  hexyl # hexdump/xxd → Colorful hex viewer
  tokei # cloc → Fast code statistics (lines, comments, languages)
  file # file → File type detection by content (enhanced classic)

  # --- System Monitoring ---------------------------------------------------------
  procs # ps → Process viewer with tree, search, and color
  bottom # top/htop → Resource monitor with graphs (btm command)
  duf # df → Disk usage with visual bars and colors
  dust # du → Directory size analyzer with tree view

  # --- Network Tools ------------------------------------------------------------
  xh # curl/wget/httpie → Modern HTTP client with intuitive syntax
  openssh # ssh → SSH client and utilities (enhanced classic)
  doggo # dig → Modern DNS client with colors and DoH/DoT support
  gping # ping → Ping with real-time graphs
  mtr # traceroute+ping → Combined network diagnostic tool

  # --- Network Analysis ---------------------------------------------------------
  bandwhich # → Terminal bandwidth monitor by process/connection
  iperf # → Network performance testing (iperf3)
  nmap # → Network exploration and security scanner
  whois # → Domain information lookup
  speedtest-cli # → Internet speed testing from terminal

  # --- Shell Enhancements -------------------------------------------------------
  zoxide # cd → Smart directory jumper with frecency (z command)
  starship # PS1 → Fast, customizable cross-shell prompt
  direnv # source → Auto-load environment variables per directory
  fzf # → Fuzzy finder for files, history, processes
  vivid # → LS_COLORS generator for better file visualization
  mcfly # ctrl+r → Smart shell history with neural network ranking

  # --- Development Tools --------------------------------------------------------
  just # make → Modern task runner with better syntax
  hyperfine # time → Command-line benchmarking tool
  jq # → JSON processor and query tool
  parallel-full # → GNU parallel for parallel command execution
  watchexec # watch → File watcher that runs commands on changes
  tldr # man → Simplified, practical man pages with examples
  ouch # tar/zip → Universal archive tool (compress/decompress)

  # --- Programs -----------------------------------------------------------------
  neovim # vim → Hyperextensible text editor

  # --- Terminal File Managers ---------------------------------------------------
  yazi # Blazing fast terminal file manager (async, image preview)
  lf # Lightweight terminal file manager (fast, minimal)
  ranger # Feature-rich terminal file manager (Python-based)
  nnn # Extremely fast terminal file manager (n³)

  # --- Zsh Enhancements ---------------------------------------------------------
  zsh-autosuggestions # Fish-like autosuggestions for command completion
  zsh-syntax-highlighting # Fish-like syntax highlighting as you type
  zsh-completions # Additional completion definitions for zsh
  zsh-history-substring-search # Fish-like history search with arrow keys
]
