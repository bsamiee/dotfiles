# Title         : rust.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/aliases/rust.nix
# ---------------------------------------
# Rust development aliases - unified mega namespace for all rust-related tools

{ lib, ... }:

let
  # --- Rust Commands (dynamically prefixed with 'r') ---------------------------
  rustCommands = {
    # Core development (single letter - highest frequency)
    b = "cargo build"; # rb - build project
    c = "cargo check"; # rc - quick check
    t = "cargo test"; # rt - run tests
    r = "cargo run"; # rr - run project

    # Code quality (consolidated - two letters)
    fmt = "cargo fmt"; # rfmt - format code
    fix = "cargo clippy --fix && cargo fmt"; # rfix - fix and format

    # Testing & coverage (consolidated)
    test = "f() { if command -v cargo-nextest &>/dev/null; then cargo nextest run \"\$@\"; else cargo test \"\$@\"; fi; }; f"; # rtest - smart test runner
    cov = "f() { if command -v cargo-tarpaulin &>/dev/null; then cargo tarpaulin --out html \"\$@\"; else echo 'Coverage requires devshell: rdl'; fi; }; f"; # rcov - coverage report

    # Development workflow (consolidated)
    watch = "f() { cargo watch -x \"\${1:-check}\" \"\${@:2}\"; }; f"; # rwatch - smart watch
    expand = "cargo expand"; # rexpand - macro expansion

    # Dependency management (consolidated)
    deps = "f() { case \"\$1\" in add|rm|up) cargo \"\$@\" ;; *) cargo tree \"\$@\" ;; esac; }; f"; # rdeps - smart dependency management
    audit = "cargo audit && cargo deny check"; # raudit - full security audit
    clean = "cargo machete && cargo outdated"; # rclean - find issues

    # Documentation (consolidated)
    doc = "f() { cargo doc \"\${@:---open}\"; }; f"; # rdoc - smart docs

    # Project management (consolidated)
    new = "f() { cargo \"\${2:-new}\" \"\$1\" \"\${@:3}\"; }; f"; # rnew - smart project creation

    # Advanced tools (semantic names)
    bacon = "bacon"; # rbacon - background compiler
    perf = "f() { if command -v cargo-flamegraph &>/dev/null; then cargo flamegraph \"\$@\"; else echo 'Profiling requires devshell: rdl'; fi; }; f"; # rperf - performance profile
    size = "cargo bloat --release"; # rsize - binary size analysis

    # WebAssembly (consolidated)
    wasm = "f() { if command -v wasm-pack &>/dev/null; then wasm-pack \"\${1:-build}\" \"\${@:2}\"; else echo 'WebAssembly requires devshell: rdl'; fi; }; f"; # rwasm - smart wasm commands

    # Quality assurance workflows (consolidated)
    qa = "cargo fmt && cargo clippy && cargo test"; # rqa - full QA
    ci = "cargo fmt --check && cargo clippy -- -D warnings && cargo test"; # rci - CI validation
    release = "cargo build --release"; # rrelease - release build

    # Development environment
    dl = "nix develop .#rust"; # rdl - enter rust devshell
  };

  # Generate prefixed aliases
  rustAliases = lib.mapAttrs' (key: value: lib.nameValuePair "r${key}" value) rustCommands;
in
{
  aliases = rustAliases;
}
