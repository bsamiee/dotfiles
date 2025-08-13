# Title         : environment.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/modules/environment.nix
# ---------------------------------------
# Single source of truth for all shell-agnostic environment variables
# Note: XDG base directories are provided by home-manager's xdg module, which is enabled in home/modules/xdg.nix
{
  config,
  ...
}:

{
  # --- Session Variables --------------------------------------------------------
  home.sessionVariables = {
    # Core System
    EDITOR = "nvim";
    VISUAL = "code --wait";
    PAGER = "less -FRX";
    BROWSER = "open"; # macOS-specific

    # --- Secrets Management ----------------------------------------------------
    # 1Password integration - these will be injected when using secrets-manager run
    # CACHIX_AUTH_TOKEN set via op run when needed
    # GITHUB_TOKEN set via op run when needed

    # --- Development Tools (XDG-compliant paths) -------------------------------
    # Rust
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";

    # Rust tooling (XDG-compliant)
    RUST_ANALYZER_CACHE_DIR = "${config.xdg.cacheHome}/rust-analyzer";
    SCCACHE_DIR = "${config.xdg.cacheHome}/sccache";
    SCCACHE_CACHE_SIZE = "10G"; # Reasonable cache size limit
    RUSTC_WRAPPER = "sccache"; # Enable compilation caching globally
    CARGO_REGISTRIES_CRATES_IO_PROTOCOL = "sparse"; # 5x faster index updates
    CARGO_NET_GIT_FETCH_WITH_CLI = "true"; # Support private repos with SSH
    CARGO_TERM_COLOR = "always"; # Colored output globally
    RUSTUP_TERM_COLOR = "always"; # Rustup colored output
    BINSTALL_DISABLE_TELEMETRY = "1"; # Disable cargo-binstall telemetry

    # Go
    GOPATH = "${config.xdg.dataHome}/go";

    # Node/npm
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    NPM_CONFIG_PREFIX = "${config.xdg.dataHome}/npm";
    NODE_REPL_HISTORY = "${config.xdg.dataHome}/node_repl_history";

    # TypeScript/JavaScript LSP
    TSSERVER_FORMAT_OPTIONS_FILE = "${config.xdg.configHome}/typescript/tsconfig.json";
    ESLINT_CONFIG_DIR = "${config.xdg.configHome}/eslint";

    # Python
    PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python/history";
    PYLINTHOME = "${config.xdg.cacheHome}/pylint";
    PYTHONDONTWRITEBYTECODE = "1"; # Don't create .pyc files globally

    # Python LSP and tools
    BASEDPYRIGHT_CACHE_DIR = "${config.xdg.cacheHome}/basedpyright";
    UV_CACHE_DIR = "${config.xdg.cacheHome}/uv";
    IPYTHONDIR = "${config.xdg.configHome}/ipython";
    JUPYTER_CONFIG_DIR = "${config.xdg.configHome}/jupyter";

    # Poetry - Better project isolation
    POETRY_VIRTUALENVS_IN_PROJECT = "true"; # .venv in project, not hidden cache
    POETRY_CONFIG_DIR = "${config.xdg.configHome}/pypoetry";
    POETRY_CACHE_DIR = "${config.xdg.cacheHome}/pypoetry";

    # Pipx - Controlled isolation
    PIPX_HOME = "${config.xdg.dataHome}/pipx";
    PIPX_BIN_DIR = "${config.xdg.dataHome}/pipx/bin";

    # Ruff - Fast Python tools
    RUFF_CACHE_DIR = "${config.xdg.cacheHome}/ruff";

    # Other development tools
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    SQLITE_HISTORY = "${config.xdg.cacheHome}/sqlite_history";
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
    MACHINE_STORAGE_PATH = "${config.xdg.dataHome}/docker-machine";
    GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";

    # Colima/Docker - Default to Colima socket (override in shell if needed)
    # Note: Shell functions handle dynamic detection
    DOCKER_BUILDKIT = "1"; # Modern builds by default
    COMPOSE_DOCKER_CLI_BUILD = "1"; # docker-compose uses BuildKit
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";

    # GitHub CLI
    GH_CONFIG_DIR = "${config.xdg.configHome}/gh";
    GH_PAGER = ""; # Disable pager for scripting

    # Additional XDG-compliant paths
    HISTFILE = "${config.xdg.stateHome}/bash/history"; # Bash history
    GNUPGHOME = "${config.xdg.dataHome}/gnupg"; # GnuPG home

    # Lua development (XDG-compliant)
    LUAROCKS_CONFIG = "${config.xdg.configHome}/luarocks/config.lua"; # LuaRocks configuration
    
    # Shell & formatting tools (XDG-compliant)
    SHELLCHECK_OPTS = "--config-file=${config.xdg.configHome}/shellcheck/shellcheckrc";
    
    # TOML formatting
    TAPLO_CONFIG = "${config.xdg.configHome}/taplo/taplo.toml"; # Override taplo config location
    
    # Markdown LSP
    MARKSMAN_CONFIG = "${config.xdg.configHome}/marksman/marksman.toml";

    # Java/JVM (XDG-compliant) - only set if using JVM languages
    JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";

    # --- Terminal Integration ---------------------------------------------------
    TERM_FEATURES = "truecolor,clipboard,title";
    COLORTERM = "truecolor";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'"; # Better man pages with bat
    LESS = "-FRX"; # Better less defaults

    # --- Package Manager Settings -----------------------------------------------
    HOMEBREW_NO_AUTO_UPDATE = "1";
    HOMEBREW_NO_ANALYTICS = "1"; # Disable homebrew telemetry
    # Note: NIXPKGS_ALLOW_UNFREE is set system-wide in darwin/modules/settings.nix

    # --- Privacy Settings -------------------------------------------------------
    DOTNET_CLI_TELEMETRY_OPTOUT = "1"; # Disable .NET telemetry
    GATSBY_TELEMETRY_DISABLED = "1"; # Disable Gatsby telemetry
    NEXT_TELEMETRY_DISABLED = "1"; # Disable Next.js telemetry
    AZURE_CORE_COLLECT_TELEMETRY = "0"; # Disable Azure CLI telemetry
    SAM_CLI_TELEMETRY = "0"; # Disable AWS SAM CLI telemetry
    POWERSHELL_TELEMETRY_OPTOUT = "1"; # Disable PowerShell telemetry
    DO_NOT_TRACK = "1"; # Universal opt-out signal

    # --- Build Performance -------------------------------------------------------
    MAKEFLAGS = "-j$(sysctl -n hw.ncpu)"; # Parallel make builds
    CMAKE_BUILD_PARALLEL_LEVEL = "$(sysctl -n hw.ncpu)"; # Parallel cmake builds

    # --- 1Password Integration -----------------------------------------------
    # Template environment file for secrets-manager
    SECRETS_TEMPLATE_FILE = "${config.xdg.configHome}/secrets/template.env";
  };

  # --- Session Path -------------------------------------------------------------
  # Shell-agnostic environment that applies to all terminals
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/bin"
    "${config.xdg.dataHome}/cargo/bin" # Rust binaries
    "${config.xdg.dataHome}/go/bin" # Go binaries
    "${config.xdg.dataHome}/pipx/bin" # Pipx-installed tools
    "${config.xdg.dataHome}/npm/bin" # npm global installs
  ];

  # --- 1Password Environment Template ------------------------------------------
  xdg.configFile."secrets/template.env".text = ''
    # 1Password Secret References Template
    # Use with: secrets-manager env $XDG_CONFIG_HOME/secrets/template.env <command>

    # Authentication tokens
    CACHIX_AUTH_TOKEN=op://Private/cachix-auth-token/credential
    GITHUB_TOKEN=op://Private/github-token/credential

    # API Keys (customize as needed)
    # OPENAI_API_KEY=op://Private/openai-api-key/credential
    # ANTHROPIC_API_KEY=op://Private/anthropic-api-key/credential

    # Database/Service URLs
    # DATABASE_URL=op://Private/database/url
    # REDIS_URL=op://Private/redis/url
  '';

  xdg.configFile."secrets/README.md".text = ''
    # Secrets Management

    Use the unified secrets manager for all secret handling:

    ## Commands
    - `secrets-manager status` - Check secrets system status
    - `secrets-manager get <key>` - Get a secret value
    - `secrets-manager set <key>` - Set a secret (will prompt)
    - `secrets-manager run <cmd>` - Run command with common secrets
    - `secrets-manager env <file> <cmd>` - Run with custom env file

    ## Environment Injection
    The template.env file contains 1Password secret references.
    Secrets are injected at runtime, never stored in plaintext.

    ## Examples
    ```bash
    # Set tokens
    secrets-manager set cachix-token
    secrets-manager set github-token

    # Generate SSH key in 1Password
    secrets-manager set ssh-key Private work-key

    # Run commands with secrets
    secrets-manager run nix build
    secrets-manager run cachix push mycache ./result

    # Custom environment
    secrets-manager env template.env npm test
    ```
  '';

}
