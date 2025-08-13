#!/usr/bin/env bash
# Title         : cachix.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : scripts/cachix.sh
# ---------------------------------------
# Comprehensive Cachix management - setup, authentication, and cache warming
set -euo pipefail

# Configuration
USERNAME="${CACHIX_USER:-$(whoami)}"
CACHE_NAME="${CACHIX_CACHE:-$USERNAME}"
FLAKE_ROOT="${DOTFILES:-$HOME/.dotfiles}"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# --- Logging Functions ---
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# --- Core Functions ---
install_cachix() {
  if ! command -v cachix &>/dev/null; then
    log_info "Installing cachix..."
    nix-env -iA nixpkgs.cachix || nix profile install nixpkgs#cachix
  fi
}

check_auth() {
  cachix authtoken &>/dev/null 2>&1
}

setup_auth_token() {
  # Check if already authenticated
  if check_auth; then
    log_success "Cachix already authenticated"
    return 0
  fi

  # Try unified secrets manager first (1Password)
  if command -v secrets-manager &>/dev/null; then
    log_info "Trying 1Password via secrets-manager..."
    if TOKEN=$(secrets-manager get cachix-token 2>/dev/null); then
      echo "$TOKEN" | cachix authtoken --stdin
      if check_auth; then
        log_success "Authenticated via 1Password"
        return 0
      fi
    fi
  fi

  # Fallback: Try encrypted secrets (SOPS)
  if [[ -f "$FLAKE_ROOT/secrets/secrets.yaml" ]] && command -v sops &>/dev/null; then
    log_info "Trying encrypted secrets (SOPS fallback)..."
    if TOKEN=$(sops --decrypt "$FLAKE_ROOT/secrets/secrets.yaml" 2>/dev/null | grep "cachix-auth-token:" | cut -d: -f2- | sed 's/^ *//' | sed 's/"//g'); then
      echo "$TOKEN" | cachix authtoken --stdin
      if check_auth; then
        log_success "Authenticated via SOPS fallback"
        return 0
      fi
    fi
  fi

  # Try environment variable
  if [ -n "${CACHIX_AUTH_TOKEN:-}" ]; then
    log_info "Using CACHIX_AUTH_TOKEN from environment..."
    echo "$CACHIX_AUTH_TOKEN" | cachix authtoken --stdin
    if check_auth; then
      log_success "Authenticated via environment variable"
      return 0
    fi
  fi

  # Manual setup required
  log_warning "Manual authentication required"
  echo ""
  echo "Authentication methods (in order of preference):"
  echo ""
  echo "1. UNIFIED SECRETS MANAGER (Recommended):"
  echo "   secrets-manager set cachix-token"
  echo "   This uses 1Password for secure token management"
  echo ""
  echo "2. LEGACY ENCRYPTED SECRETS:"
  echo "   Run: ./scripts/bootstrap-secrets.sh"
  echo "   This sets up SOPS-based token management"
  echo ""
  echo "3. MANUAL TOKEN ENTRY:"
  echo "   Get token from: https://app.cachix.org/personal-auth-tokens"
  echo "   Run: cachix authtoken"
  echo ""
  echo "4. ENVIRONMENT VARIABLE:"
  echo "   export CACHIX_AUTH_TOKEN='your-token'"
  echo ""
  return 1
}

setup_cache() {
  # Create or use cache
  log_info "Setting up cache: $CACHE_NAME"

  if cachix use "$CACHE_NAME" &>/dev/null 2>&1; then
    log_success "Using existing cache: $CACHE_NAME"
  else
    log_info "Creating new cache: $CACHE_NAME"
    if cachix create "$CACHE_NAME" &>/dev/null 2>&1; then
      log_success "Cache created: $CACHE_NAME"
    else
      log_warning "Could not create cache (may already exist or require different permissions)"
    fi
  fi

  # Get public key for reference
  PUBLIC_KEY=$(cachix use "$CACHE_NAME" 2>&1 | grep -oE "$CACHE_NAME\.cachix\.org-[^\"]+") || true
  if [ -n "$PUBLIC_KEY" ]; then
    log_info "Public key: $PUBLIC_KEY"
    echo ""
    echo "Note: Cache configuration is managed in darwin/modules/cache.nix"
    echo "The public key above can be added there if needed."
  fi
}

setup_daemon() {
  log_info "Setting up Cachix daemon..."

  # Check if daemon is already running
  if pgrep -x "cachix" >/dev/null; then
    log_success "Cachix daemon already running"
    return 0
  fi

  # Start daemon (will be managed by launchd via cache.nix)
  log_info "Daemon will be started by launchd on next rebuild"
  log_info "Run 'darwin-rebuild switch' to activate"
}

# --- Cache Warming Functions ---
warm_flake_inputs() {
  log_info "Warming flake inputs..."
  cd "$FLAKE_ROOT"

  # Archive flake and all inputs
  nix flake archive --json 2>/dev/null |
    jq -r '.path,(.inputs|to_entries[].value.path)' |
    while read -r path; do
      if [ -n "$path" ]; then
        log_info "  Pushing: $path"
        cachix push "$CACHE_NAME" "$path" &>/dev/null || true
      fi
    done

  log_success "Flake inputs warmed!"
}

warm_dev_shells() {
  log_info "Warming development shells..."
  cd "$FLAKE_ROOT"

  # Build and cache default devshell
  if nix develop --profile /tmp/dev-profile-$$ -c true 2>/dev/null; then
    cachix push "$CACHE_NAME" /tmp/dev-profile-$$ &>/dev/null || true
    rm -f /tmp/dev-profile-$$*
    log_success "  Default devshell cached"
  fi

  # Build Python devshell if it exists
  if nix develop .#python --profile /tmp/dev-python-$$ -c true 2>/dev/null; then
    cachix push "$CACHE_NAME" /tmp/dev-python-$$ &>/dev/null || true
    rm -f /tmp/dev-python-$$*
    log_success "  Python devshell cached"
  fi

  log_success "Development shells warmed!"
}

warm_darwin_config() {
  log_info "Warming Darwin configuration..."
  cd "$FLAKE_ROOT"

  # Build but don't switch
  if darwin-rebuild build --flake . 2>/dev/null; then
    # Push the result
    if [ -L "result" ]; then
      cachix push "$CACHE_NAME" ./result &>/dev/null || true
      rm -f result
      log_success "Darwin configuration cached"
    fi
  else
    log_warning "Failed to build Darwin configuration"
  fi
}

warm_common_packages() {
  log_info "Warming common packages..."

  # List of commonly used packages to pre-cache
  local packages=(
    "nixpkgs#cachix"
    "nixpkgs#git"
    "nixpkgs#ripgrep"
    "nixpkgs#fd"
    "nixpkgs#bat"
    "nixpkgs#jq"
    "nixpkgs#tree"
    "nixpkgs#htop"
  )

  for pkg in "${packages[@]}"; do
    log_info "  Building: $pkg"
    if nix build "$pkg" --no-link 2>/dev/null; then
      # Get store path and push
      STORE_PATH=$(nix eval --raw "$pkg")
      if [ -n "$STORE_PATH" ]; then
        cachix push "$CACHE_NAME" "$STORE_PATH" &>/dev/null || true
      fi
    fi
  done

  log_success "Common packages warmed!"
}

# --- Command Functions ---
cmd_setup() {
  echo -e "${BLUE}=== Cachix Setup ===${NC}"
  echo "Cache name: $CACHE_NAME"
  echo ""

  # Install cachix if needed
  install_cachix

  # Setup authentication
  if ! setup_auth_token; then
    exit 1
  fi

  # Setup cache
  setup_cache

  # Setup daemon
  setup_daemon

  # Verify everything
  cmd_status

  log_success "Cachix setup complete!"
  echo ""
  echo "Next steps:"
  echo "  1. Run 'darwin-rebuild switch' to activate daemon"
  echo "  2. Run '$0 warm' to warm the cache"
  echo "  3. Run 'nhealth' to check cache status"
}

cmd_warm() {
  echo -e "${BLUE}=== Cache Warming ===${NC}"
  echo "Cache: $CACHE_NAME"
  echo ""

  # Check prerequisites
  if ! check_auth; then
    log_error "Cachix not authenticated. Run: $0 setup"
    exit 1
  fi

  # Parse warming target
  case "${1:-all}" in
    inputs)
      warm_flake_inputs
      ;;
    dev)
      warm_dev_shells
      ;;
    darwin)
      warm_darwin_config
      ;;
    packages)
      warm_common_packages
      ;;
    all)
      warm_flake_inputs
      warm_dev_shells
      warm_darwin_config
      warm_common_packages
      ;;
    *)
      echo "Usage: $0 warm [inputs|dev|darwin|packages|all]"
      echo ""
      echo "  inputs   - Cache flake inputs"
      echo "  dev      - Cache development shells"
      echo "  darwin   - Cache Darwin configuration"
      echo "  packages - Cache common packages"
      echo "  all      - Cache everything (default)"
      exit 1
      ;;
  esac

  echo ""
  log_success "Cache warming complete!"
}

cmd_status() {
  echo -e "${BLUE}=== Cachix Status ===${NC}"
  echo ""

  # Check authentication
  if check_auth; then
    echo -e "  Authentication: ${GREEN}✓${NC}"
  else
    echo -e "  Authentication: ${YELLOW}✗${NC}"
  fi

  # Check cache
  if cachix use "$CACHE_NAME" &>/dev/null 2>&1; then
    echo -e "  Cache access:   ${GREEN}✓${NC} ($CACHE_NAME)"
  else
    echo -e "  Cache access:   ${YELLOW}✗${NC}"
  fi

  # Check daemon
  if pgrep -x "cachix" >/dev/null; then
    echo -e "  Daemon:         ${GREEN}✓${NC}"
  else
    echo -e "  Daemon:         ${YELLOW}○${NC} (not running)"
  fi

  echo ""
}

cmd_help() {
  cat <<EOF
Usage: $0 [COMMAND] [OPTIONS]

Comprehensive Cachix management for Nix builds

COMMANDS:
  setup           Set up Cachix authentication and cache
  warm [TARGET]   Warm the cache with pre-built derivations
  status          Show current Cachix status
  help            Show this help message

WARM TARGETS:
  all             Warm everything (default)
  inputs          Cache flake inputs only
  dev             Cache development shells only
  darwin          Cache Darwin configuration only
  packages        Cache common packages only

EXAMPLES:
  $0 setup        # Initial Cachix setup
  $0 warm         # Warm all caches
  $0 warm dev     # Warm only dev shells
  $0 status       # Check cache status

ENVIRONMENT:
  CACHIX_CACHE    Override cache name (default: username)
  CACHIX_AUTH_TOKEN  Provide token for automatic auth
EOF
}

# --- Main ---
main() {
  case "${1:-help}" in
    setup)
      cmd_setup
      ;;
    warm)
      shift
      cmd_warm "$@"
      ;;
    status)
      cmd_status
      ;;
    help | --help | -h)
      cmd_help
      ;;
    *)
      log_error "Unknown command: $1"
      cmd_help
      exit 1
      ;;
  esac
}

main "$@"
