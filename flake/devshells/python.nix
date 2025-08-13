# Title         : python.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : flake/devshells/python.nix
# ---------------------------------------
# Project-specific Python development environment
# Assumes global Python tools are installed via package suites
{
  pkgs,
  ...
}:

let
  # Default Python version (can be overridden per project)
  python = pkgs.python313;
in
pkgs.mkShell {
  name = "python-project-dev";

  # Only project-specific tools (assumes globals from package suites)
  packages = [
    python # Specific Python version for this project
  ];

  # Project-specific environment variables (complementing global environment.nix)
  env = {
    # Override global Python version for this project
    PYTHON_VERSION = python.version;
    UV_PYTHON = "${python}/bin/python";
    POETRY_PYTHON = "${python}/bin/python";

    # Project-specific paths (properly extends global PYTHONPATH)
    PYTHONPATH = "$PWD/src:$PWD/libs:$PWD/tests:\${PYTHONPATH:-}";

    # Development-only settings
    PYTHONUNBUFFERED = "1"; # Force stdout/stderr to be unbuffered
    PYTHONUTF8 = "1"; # Force UTF-8 encoding
    PYTHONPROFILEIMPORTTIME = "1"; # Show import time profiling
    PYTHONWARNINGS = "default"; # Show deprecation warnings

    # Project-local cache directories (for reproducibility)
    # These override global XDG settings intentionally for project isolation
    PRE_COMMIT_HOME = "$PWD/.cache/pre-commit";
    NOX_CACHE_DIR = "$PWD/.cache/nox";
    # Note: UV_CACHE_DIR, BASEDPYRIGHT_CACHE_DIR, RUFF_CACHE_DIR, and POETRY_*
    # intentionally use global XDG paths from environment.nix for efficiency
  };

  shellHook = ''
    echo "═══════════════════════════════════════════════════════"
    echo "  Python ${python.version} Project Development Environment"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "Project Setup:"
    echo "  Python: ${python}/bin/python"
    echo "  Cache:  .cache/ (project-local)"
    echo "  Venv:   .venv/ (project-local)"
    echo ""

    # Smart project detection and setup
    if [ -f "pyproject.toml" ]; then
      echo "📦 Project detected: pyproject.toml found"

      # Dependency analysis for service recommendations
      NEEDS_POSTGRES=""
      NEEDS_REDIS=""
      NEEDS_DOCKER=""

      if grep -q -E "(asyncpg|psycopg|sqlalchemy|alembic)" pyproject.toml; then
        NEEDS_POSTGRES="true"
      fi

      if grep -q -E "(redis|celery|aiocache|arq)" pyproject.toml; then
        NEEDS_REDIS="true"
      fi

      if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
        NEEDS_DOCKER="true"
      fi

      # Virtual environment management
      if [ -d ".venv" ]; then
        echo "🐍 Activating virtual environment..."
        source .venv/bin/activate
        echo "   Virtual environment: $(python --version) in .venv/"
      else
        echo "💡 Create virtual environment with: poetry install"
      fi

      # Service recommendations (non-intrusive)
      if [ -n "$NEEDS_POSTGRES" ] || [ -n "$NEEDS_REDIS" ] || [ -n "$NEEDS_DOCKER" ]; then
        echo ""
        echo "🔧 Services detected in dependencies:"
        [ -n "$NEEDS_POSTGRES" ] && echo "   • PostgreSQL (database dependencies found)"
        [ -n "$NEEDS_REDIS" ] && echo "   • Redis (cache/queue dependencies found)"
        [ -n "$NEEDS_DOCKER" ] && echo "   • Docker services (compose file found)"
        echo "   💡 Configure services in docker-compose.yml or use global services"
      fi

      # Development workflow hints
      echo ""
      echo "🚀 Common commands:"
      echo "   poetry install    - Install dependencies"
      echo "   poetry run pytest - Run tests"
      echo "   poetry run ruff   - Lint code (if ruff installed globally)"
      echo "   pre-commit install - Setup git hooks (if pre-commit installed globally)"

    elif [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
      echo "📦 Legacy Python project detected"
      echo "💡 Consider migrating to pyproject.toml for modern tooling"

      # Basic venv setup for legacy projects
      if [ -d ".venv" ]; then
        echo "🐍 Activating virtual environment..."
        source .venv/bin/activate
      else
        echo "💡 Create virtual environment with: python -m venv .venv && source .venv/bin/activate"
      fi

    else
      echo "📁 General Python development environment"
      echo "💡 Create a new project with: poetry new project-name"
    fi

    echo ""
  '';
}
