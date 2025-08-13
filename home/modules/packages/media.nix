# Title         : media.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/modules/packages/media.nix
# ---------------------------------------
# Media processing and manipulation tools

{ pkgs, ... }:

with pkgs;
[
  # --- Media Processing Tools ---------------------------------------------------
  ffmpeg # NEW TOOL ADDED - PENDING CONFIGURATION - Complete multimedia framework
  imagemagick # NEW TOOL ADDED - PENDING CONFIGURATION - Image manipulation
  yt-dlp # NEW TOOL ADDED - PENDING CONFIGURATION - Video downloader
  pandoc # NEW TOOL ADDED - PENDING CONFIGURATION - Universal document converter
  graphviz # NEW TOOL ADDED - PENDING CONFIGURATION - Graph visualization software
]
