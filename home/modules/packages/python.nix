# Title         : python.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/modules/packages/python.nix
# ---------------------------------------
# Python development environment and scientific computing tools

{ pkgs, ... }:

with pkgs;
[
  # --- Python Toolchain ---------------------------------------------------------
  python313 # Python 3.13
  pipx # Install Python apps in isolated environments
  poetry # Python dependency management
  ruff # Fast Python linter/formatter
  uv # Fast Python package installer and resolver
  basedpyright # Type checker for Python (better than pyright)

  # --- Python Development Utilities --------------------------------------------
  cookiecutter # Project template tool
  python3Packages.black # NEW TOOL ADDED - PENDING CONFIGURATION - Python code formatter
  python3Packages.mypy # NEW TOOL ADDED - PENDING CONFIGURATION - Static type checker
  python3Packages.pytest # NEW TOOL ADDED - PENDING CONFIGURATION - Testing framework
  python3Packages.ipython # NEW TOOL ADDED - PENDING CONFIGURATION - Enhanced Python shell
  python3Packages.jupyterlab # NEW TOOL ADDED - PENDING CONFIGURATION - Jupyter IDE
  python3Packages.rich # NEW TOOL ADDED - PENDING CONFIGURATION - Rich text formatting
  python3Packages.typer # NEW TOOL ADDED - PENDING CONFIGURATION - CLI creation library
  python3Packages.pydantic # NEW TOOL ADDED - PENDING CONFIGURATION - Data validation
  python3Packages.httpx # NEW TOOL ADDED - PENDING CONFIGURATION - Modern HTTP client
]
