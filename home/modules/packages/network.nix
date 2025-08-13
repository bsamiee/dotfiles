# Title         : network.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/modules/packages/network.nix
# ---------------------------------------
# Network diagnostics, monitoring, and HTTP tools

{ pkgs, ... }:

with pkgs;
[
  nmap # Network exploration and security scanner

  # --- Network Diagnostic Tools -------------------------------------------------

  # --- HTTP Clients & Testing ---------------------------------------------------

  # --- Network Diagnostic Tools ------------------------------------------------
  speedtest-cli # Command-line speed test
  bandwhich # Terminal bandwidth monitor
  iperf # Network performance testing (iperf3)

  # --- DNS & Domain Tools -------------------------------------------------------
  bind # DNS tools (includes dig)
  whois # Domain information lookup
]
