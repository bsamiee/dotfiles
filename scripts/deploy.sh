#!/usr/bin/env bash
# Title         : deploy.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : scripts/deploy.sh
# ---------------------------------------
# Smart deployment script for remote Nix configurations
set -euo pipefail

# Configuration
FLAKE_ROOT="${DOTFILES:-$HOME/.dotfiles}"
DEFAULT_ACTION="switch"

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

# --- Usage and Help ---
usage() {
  cat <<EOF
Usage: $0 [SERVER] [ACTION] [OPTIONS]

Smart deployment script for remote Nix configurations using deploy-rs.

ARGUMENTS:
  SERVER          Target server name (from flake outputs)
  ACTION          Deployment action (default: switch)

ACTIONS:
  switch          Deploy and activate configuration (default)
  build           Build configuration remotely without activating
  check           Check configuration validity
  dry-run         Show what would be deployed without changes
  rollback        Rollback to previous generation

OPTIONS:
  -f, --force     Force deployment even with warnings
  -v, --verbose   Verbose output
  -h, --help      Show this help message

EXAMPLES:
  $0                      # List available servers
  $0 server1              # Deploy to server1 (switch)
  $0 server1 build        # Build on server1 without switching
  $0 server1 dry-run      # Preview deployment to server1
  $0 server1 check        # Validate server1 configuration
  $0 server1 rollback     # Rollback server1 to previous generation

REQUIREMENTS:
  - deploy-rs installed and configured
  - SSH access to target servers
  - Server configurations defined in flake.nix

EOF
  exit 0
}

# --- Core Functions ---
check_prerequisites() {
  # Check if deploy-rs is available
  if ! command -v deploy &>/dev/null; then
    log_error "deploy-rs not found. Install with: nix profile install github:serokell/deploy-rs"
    exit 1
  fi

  # Ensure we're in the flake directory
  cd "$FLAKE_ROOT"

  # Check if flake has deploy configurations
  if ! nix flake show 2>/dev/null | grep -q "deploy"; then
    log_warning "No deploy configurations found in flake"
    echo "Add deploy configurations to your flake.nix. Example:"
    echo ""
    echo "  deploy.nodes = {"
    echo "    server1 = {"
    echo '      hostname = "server1.example.com";'
    echo "      profiles.system = {"
    echo '        user = "root";'
    echo "        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.server1;"
    echo "      };"
    echo "    };"
    echo "  };"
    return 1
  fi
}

list_servers() {
  log_info "Available servers:"
  echo ""
  nix flake show 2>/dev/null | grep -A 10 "deploy" | grep -E "^\s+[a-zA-Z]" | sed 's/^[[:space:]]*/  /' || {
    log_warning "No servers configured or flake evaluation failed"
    return 1
  }
  echo ""
  echo "Configure servers in flake.nix deploy.nodes section"
}

validate_server() {
  local server="$1"

  # Check if server exists in flake
  if ! nix flake show 2>/dev/null | grep -q "$server"; then
    log_error "Server '$server' not found in flake configuration"
    echo ""
    list_servers
    exit 1
  fi
}

test_connectivity() {
  local server="$1"

  log_info "Testing connectivity to $server..."

  # Get hostname from flake (this is a simplified approach)
  # In a real implementation, you'd parse the flake output properly
  if deploy --dry-run ".#$server" &>/dev/null; then
    log_success "Connection to $server verified"
  else
    log_warning "Cannot connect to $server or configuration invalid"
    return 1
  fi
}

# --- Deployment Functions ---
deploy_server() {
  local server="$1"
  local action="${2:-$DEFAULT_ACTION}"
  local force="${3:-false}"
  local verbose="${4:-false}"

  log_info "Deploying to $server with action: $action"

  # Build deploy command
  local cmd="deploy"
  local target=".#$server"

  case "$action" in
    switch)
      # Default - no extra flags needed
      ;;
    build)
      cmd="$cmd --dry-activate"
      ;;
    check)
      cmd="$cmd --dry-run"
      log_info "Checking configuration (dry-run mode)"
      ;;
    dry-run)
      cmd="$cmd --dry-run"
      ;;
    rollback)
      log_info "Rolling back $server to previous generation"
      # deploy-rs doesn't have direct rollback, use SSH
      log_warning "Rollback requires manual SSH connection"
      echo "Run: ssh $server 'nixos-rebuild switch --rollback'"
      return 0
      ;;
    *)
      log_error "Unknown action: $action"
      exit 1
      ;;
  esac

  # Add verbose flag if requested
  if [[ $verbose == "true" ]]; then
    cmd="$cmd --verbose"
  fi

  # Add force flag if requested
  if [[ $force == "true" ]]; then
    cmd="$cmd --force"
  fi

  # Execute deployment
  log_info "Running: $cmd $target"

  if $cmd "$target"; then
    log_success "Deployment to $server completed successfully"

    # Send notification if available
    if command -v terminal-notifier &>/dev/null; then
      terminal-notifier -title "Nix Deploy" \
        -subtitle "$server deployment" \
        -message "Action '$action' completed successfully" \
        -group "nix-deploy" &>/dev/null &
    fi
  else
    log_error "Deployment to $server failed"
    exit 1
  fi
}

# --- Main Script ---
main() {
  local server=""
  local action="$DEFAULT_ACTION"
  local force=false
  local verbose=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f | --force)
        force=true
        shift
        ;;
      -v | --verbose)
        verbose=true
        shift
        ;;
      -h | --help)
        usage
        ;;
      -*)
        log_error "Unknown option: $1"
        usage
        ;;
      *)
        if [[ -z $server ]]; then
          server="$1"
        elif [[ -z $action ]] || [[ $action == "$DEFAULT_ACTION" ]]; then
          action="$1"
        else
          log_error "Too many arguments"
          usage
        fi
        shift
        ;;
    esac
  done

  # Check prerequisites
  if ! check_prerequisites; then
    exit 1
  fi

  # If no server specified, list available servers
  if [[ -z $server ]]; then
    list_servers
    exit 0
  fi

  # Validate server exists
  validate_server "$server"

  # Test connectivity (optional, can be skipped with --force)
  if [[ $force != "true" ]]; then
    if ! test_connectivity "$server"; then
      log_error "Connectivity test failed. Use --force to skip."
      exit 1
    fi
  fi

  # Perform deployment
  deploy_server "$server" "$action" "$force" "$verbose"
}

# Execute main function with all arguments
main "$@"
