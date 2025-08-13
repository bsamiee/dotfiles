# Title         : lua.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/shells/aliases/lua.nix
# ---------------------------------------
# Lua development aliases - unified mega namespace for all lua-related tools

{ lib, ... }:

let
  # --- Lua Commands (dynamically prefixed with 'l') -----------------------------
  luaCommands = {
    # Core execution (single letter - highest frequency)
    u = "lua"; # lu - lua interpreter
    j = "luajit"; # lj - luajit interpreter
    r = "luarocks"; # lr - package manager

    # Development environment (intelligent consolidation)
    dl = "nix develop .#lua"; # ldl - enter lua devshell
    repl = "f() { if [[ -f .luajitrc || -f luajit.conf ]]; then luajit -i \"\$@\"; else lua -i \"\$@\"; fi; }; f"; # lrepl - smart interactive REPL
    eval = "f() { if [[ -f .luajitrc || -f luajit.conf ]]; then luajit -e \"\$@\"; else lua -e \"\$@\"; fi; }; f"; # leval - smart expression evaluation

    # Code quality & formatting (unified semantics)
    fmt = "f() { stylua \"\${@:-.}\"; }; f"; # lfmt - format files
    fmtc = "f() { stylua --check \"\${@:-.}\"; }; f"; # lfmtc - check formatting
    lint = "f() { lua-language-server --check \"\${@:-.}\" 2>/dev/null || echo 'LSP linting requires editor integration'; }; f"; # llint - LSP diagnostics (best in editor)

    # Package management (semantic)
    install = "luarocks install --local"; # linstall - install package locally
    remove = "luarocks remove"; # lremove - remove package
    list = "luarocks list"; # llist - list installed packages
    search = "luarocks search"; # lsearch - search packages
    show = "luarocks show"; # lshow - show package info
    make = "luarocks make"; # lmake - build from rockspec
    path = "luarocks path"; # lpath - show lua paths for environment

    # Testing & coverage (devshell tools - semantic)
    test = "busted"; # ltest - run tests
    testf = "busted --filter"; # ltestf - filter tests by pattern
    testt = "busted --tags"; # ltestt - run tagged tests only
    cov = "busted --coverage && luacov"; # lcov - run tests with coverage and generate report

    # Project scaffolding (semantic)
    init = "f() { luarocks init \"\${1:-.}\" && echo 'use flake' > .envrc && direnv allow; }; f"; # linit - initialize lua project with direnv
    rock = "luarocks write_rockspec"; # lrock - generate rockspec

    # Smart interpreter selection (intelligent consolidation)
    run = "f() { if [[ -f .luajitrc || -f luajit.conf ]]; then luajit \"\$@\"; else lua \"\$@\"; fi; }; f"; # lrun - smart lua/luajit selection

    # Documentation & help
    help = "echo 'Lua: lua.org/manual | LuaRocks: luarocks.org'"; # lhelp - lua tools help
    version = "lua -v 2>&1 && luajit -v 2>&1 && luarocks --version | head -1"; # lversion - show all versions
  };
in
{
  aliases = lib.mapAttrs' (name: value: {
    # Export aliases with 'l' prefix
    name = "l${name}";
    inherit value;
  }) luaCommands;
}
