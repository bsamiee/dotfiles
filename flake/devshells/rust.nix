# Title         : rust.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : flake/devshells/rust.nix
# ---------------------------------------
# Project-specific Rust development environment
# Assumes global Rust tools are installed via package suites

{
  pkgs,
  ...
}:

pkgs.mkShell {
  name = "rust-project-dev";

  # Advanced project-specific tools (assumes globals: rustc, cargo, rustfmt, clippy, sccache)
  packages = with pkgs; [
    # --- Advanced Testing & Coverage -----------------------------------------
    cargo-nextest # Faster test runner
    cargo-tarpaulin # Code coverage tool (cargo-llvm-cov is broken on macOS)

    # --- WebAssembly Tools (specialized development) ------------------------
    wasm-pack # WebAssembly toolchain
    wasmtime # WebAssembly runtime for testing

    # --- Performance & Profiling (advanced analysis) -----------------------
    cargo-flamegraph # Performance profiling
    # valgrind is not available on macOS ARM64
  ];

  # Project-specific environment variables (complementing global environment.nix)
  env = {
    # Development-only settings
    RUST_BACKTRACE = "1"; # Full backtraces for debugging
    RUST_LOG = "debug"; # Default log level for development
    RUSTFLAGS = "-D warnings"; # Treat warnings as errors in development

    # WebAssembly specific settings (if using wasm-pack)
    WASM_PACK_CACHE = "$PWD/.cache/wasm-pack";

    # Test configuration
    NEXTEST_PROFILE = "ci"; # Use CI profile for thorough testing
    
    # Note: The following are inherited from global config:
    # - RUSTC_WRAPPER (sccache)
    # - CARGO_TERM_COLOR (always)
    # - CARGO_HOME, RUSTUP_HOME (XDG paths)
    # - CARGO_REGISTRIES_CRATES_IO_PROTOCOL (sparse)
  };

  shellHook = ''
    echo "═══════════════════════════════════════════════════════"
    echo "  Rust Project Development Environment"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "Project Setup:"
    echo "  Rust: $(rustc --version)"
    echo "  Target: $PWD/target/"
    echo "  Cache: $CARGO_HOME (XDG-compliant)"
    echo ""

    # Smart project detection and setup
    if [ -f "Cargo.toml" ]; then
      echo "🦀 Rust project detected: Cargo.toml found"
      
      # Check for workspace vs single crate
      if grep -q "^\[workspace\]" Cargo.toml; then
        echo "📦 Workspace detected with multiple crates"
        WORKSPACE_MEMBERS=$(grep -A 10 "^\[workspace\]" Cargo.toml | grep "members" | head -1)
        if [ -n "$WORKSPACE_MEMBERS" ]; then
          echo "   Members: $WORKSPACE_MEMBERS"
        fi
      else
        echo "📦 Single crate project"
        CRATE_NAME=$(grep "^name" Cargo.toml | head -1 | cut -d'"' -f2)
        if [ -n "$CRATE_NAME" ]; then
          echo "   Crate: $CRATE_NAME"
        fi
      fi

      # Dependency analysis for workflow recommendations
      NEEDS_WASM=""
      NEEDS_ASYNC=""
      NEEDS_CLI=""
      
      if grep -q -E "(wasm-bindgen|web-sys|js-sys)" Cargo.toml; then
        NEEDS_WASM="true"
      fi
      
      if grep -q -E "(tokio|async-std|futures)" Cargo.toml; then
        NEEDS_ASYNC="true"
      fi
      
      if grep -q -E "(clap|structopt|argh)" Cargo.toml; then
        NEEDS_CLI="true"
      fi

      # Workflow recommendations (non-intrusive)
      if [ -n "$NEEDS_WASM" ] || [ -n "$NEEDS_ASYNC" ] || [ -n "$NEEDS_CLI" ]; then
        echo ""
        echo "🔧 Project patterns detected:"
        [ -n "$NEEDS_WASM" ] && echo "   • WebAssembly (wasm-pack available)"
        [ -n "$NEEDS_ASYNC" ] && echo "   • Async runtime (tokio/async-std)"
        [ -n "$NEEDS_CLI" ] && echo "   • CLI application (clap/structopt)"
      fi

      # Check for rust-toolchain.toml
      if [ -f "rust-toolchain.toml" ] || [ -f "rust-toolchain" ]; then
        echo ""
        echo "🔧 Project-specific toolchain detected"
        echo "   💡 Using project toolchain over devshell default"
      fi

      # Development workflow hints
      echo ""
      echo "🚀 Common commands:"
      echo "   cargo check       - Quick compilation check"
      echo "   cargo clippy      - Lint code"
      echo "   cargo fmt         - Format code"
      echo "   cargo nextest run - Fast test execution"
      echo "   cargo tarpaulin   - Code coverage analysis"
      echo "   bacon             - Background compilation"
      
      if [ -n "$NEEDS_WASM" ]; then
        echo "   wasm-pack build   - Build WebAssembly package"
      fi

    elif [ -f "Cargo.lock" ]; then
      echo "🦀 Rust project detected (Cargo.lock found, missing Cargo.toml)"
      echo "💡 This might be a git submodule or incomplete project"
      
    else
      echo "📁 General Rust development environment"
      echo "💡 Create a new project with: cargo new project-name"
      echo "💡 Or generate from template: cargo generate <template>"
    fi

    echo ""
  '';
}
