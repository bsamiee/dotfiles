# Title         : lua.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : flake/devshells/lua.nix
# ---------------------------------------
# Lua development shell with advanced tooling

{
  pkgs,
  ...
}:

pkgs.mkShell {
  name = "lua-dev";

  packages = with pkgs; [
    # --- Core Lua Tools (TEMPORARY) ----------------------------------------------
    # TODO: Remove after darwin-rebuild switch - these will be globally available
    lua
    luajit
    luarocks
    lua-language-server
    stylua

    # --- Additional Development Tools (devshell-only) ----------------------------
    luajitPackages.penlight # Useful Lua libraries for testing
    luajitPackages.busted # Unit testing framework
    luajitPackages.luacov # Code coverage tool
  ];

  shellHook = ''
    echo "═══════════════════════════════════════════════════════"
    echo "  Lua Development Environment"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "🚀 Core Tools:"
    echo "  lua               - Lua interpreter"
    echo "  luajit            - JIT compiler"
    echo "  luarocks          - Package manager"
    echo ""
    echo "🔧 Development Tools:"
    echo "  lua-language-server - LSP for IDE integration"
    echo "  stylua            - Code formatter"
    echo ""
    echo "🧪 Testing Tools:"
    echo "  busted            - Unit testing framework"
    echo "  luacov            - Code coverage"
    echo ""
    echo "💡 Quick commands:"
    echo "  stylua .          - Format all Lua files"
    echo "  stylua --check .  - Check formatting"
    echo "  busted            - Run tests"
    echo ""
  '';

  # --- Environment Variables ----------------------------------------------------
  env = {
    LUA_PATH = "${pkgs.luajitPackages.penlight}/share/lua/5.1/?.lua;${pkgs.luajitPackages.penlight}/share/lua/5.1/?/init.lua;./?.lua;./?/init.lua";
    LUA_CPATH = "${pkgs.luajitPackages.penlight}/lib/lua/5.1/?.so;./?.so";
  };
}
