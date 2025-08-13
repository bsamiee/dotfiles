# Title         : lua.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/modules/packages/lua.nix
# ---------------------------------------
# Lua development environment and tooling

{ pkgs, ... }:

with pkgs;
[
  # --- Lua Runtime & Package Management -----------------------------------------
  lua # Lua interpreter (latest stable)
  luajit # Just-In-Time Lua compiler
  luarocks # Lua package manager

  # --- Language Server & Intelligence -------------------------------------------
  lua-language-server # LSP for Lua (sumneko/LuaLS) - provides linting & diagnostics

  # --- Code Quality Tools -------------------------------------------------------
  stylua # Opinionated Lua code formatter (most modern)
]
