#!/usr/bin/env bash
# Title         : secrets-manager.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : scripts/secrets-manager.sh
# ---------------------------------------
# Unified secrets management interface using 1Password

set -euo pipefail

# --- Configuration & Globals --------------------------------------------------
readonly SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES="${DOTFILES:-$(dirname "$SCRIPT_DIR")}"

# Source helper libraries
# shellcheck disable=SC1091  # 1Password helpers - sourcing expected here
source "$DOTFILES/lib/1password.sh" 2>/dev/null || {
	echo "Error: 1Password helpers not available"
	exit 1
}

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# --- Logging Functions --------------------------------------------------------
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Core Functions -----------------------------------------------------------
check_dependencies() {
	if ! command -v op &>/dev/null; then
		log_error "1Password CLI not installed"
		echo ""
		echo "Install with:"
		echo "  macOS: Already installed via Nix (check nix profile)"
		echo "  Manual: brew install 1password-cli"
		echo ""
		echo "Then sign in with: op signin"
		return 1
	fi
}

get_secret() {
	local key="$1"
	local vault="${2:-Private}"

	if ! op_available; then
		log_error "1Password CLI not available"
		return 1
	fi

	case "$key" in
	cachix-token | cachix-auth-token)
		op_get_secret "cachix-auth-token" "$vault"
		;;
	github-token)
		op_get_secret "github-token" "$vault"
		;;
	*)
		# Try generic lookup
		op_get_secret "$key" "$vault"
		;;
	esac
}

set_secret() {
	local key="$1"
	local value="$2"
	local vault="${3:-Private}"

	if ! op_available; then
		log_error "1Password CLI not available. Cannot set secrets."
		return 1
	fi

	case "$key" in
	cachix-token | cachix-auth-token)
		op_set_secret "Cachix Auth Token" "cachix-auth-token" "$value" "$vault"
		;;
	github-token)
		op_set_secret "GitHub Token" "github-token" "$value" "$vault"
		;;
	ssh-key)
		# Generate new SSH key in 1Password
		if op_generate_ssh_key "${4:-dev-key}" "$vault"; then
			log_success "SSH key generated in 1Password"
		else
			log_error "Failed to generate SSH key"
			return 1
		fi
		;;
	*)
		op_set_secret "$key" "$key" "$value" "$vault"
		;;
	esac
}

env_run() {
	local env_file="$1"
	shift

	if ! op_available; then
		log_error "1Password CLI not available"
		return 1
	fi

	log_info "Running with 1Password environment injection..."
	op_run_with_env "$env_file" "$@"
}

# --- Status & Diagnostics -----------------------------------------------------
cmd_status() {
	echo -e "${BLUE}=== Secrets Management Status ===${NC}"
	echo ""

	# Check 1Password
	if op_available; then
		echo -e "  1Password CLI: ${GREEN}✓${NC}"
		if op_authenticated; then
			echo -e "  Authentication: ${GREEN}✓${NC}"

			# Get account info
			local account
			account=$(op account get --format=json 2>/dev/null | jq -r '.email' 2>/dev/null || echo "unknown")
			echo -e "  Account: $account"
		else
			echo -e "  Authentication: ${YELLOW}✗${NC} (run 'op signin')"
		fi
	else
		echo -e "  1Password CLI: ${RED}✗${NC}"
	fi

	echo ""

	# Check SSH agent
	local socket_path
	socket_path=$(get_1password_socket_path)
	if [[ -S $socket_path ]]; then
		echo -e "  SSH Agent Socket: ${GREEN}✓${NC}"
	else
		echo -e "  SSH Agent Socket: ${YELLOW}✗${NC} (Enable in 1Password app)"
	fi

	echo ""

	# Check key secrets
	echo "Secret Status:"
	for secret in "cachix-token" "github-token"; do
		if get_secret "$secret" >/dev/null 2>&1; then
			echo -e "  $secret: ${GREEN}✓${NC}"
		else
			echo -e "  $secret: ${YELLOW}✗${NC}"
		fi
	done

	# Check SSH keys
	echo ""
	echo "SSH Keys:"
	# shellcheck disable=SC2119 # Using default vault parameter
	op_list_ssh_keys 2>/dev/null || echo "  No SSH keys found"

	echo ""
}

cmd_get() {
	local key="${1:-}"
	if [[ -z $key ]]; then
		log_error "Usage: $0 get <key> [vault]"
		exit 1
	fi

	local vault="${2:-Private}"

	if value=$(get_secret "$key" "$vault"); then
		echo "$value"
	else
		log_error "Failed to get secret: $key"
		exit 1
	fi
}

cmd_set() {
	local key="${1:-}"
	local value="${2:-}"

	if [[ -z $key ]]; then
		log_error "Usage: $0 set <key> [value] [vault] [name-for-ssh]"
		exit 1
	fi

	# Special handling for SSH keys
	if [[ $key == "ssh-key" ]]; then
		set_secret "$key" "" "${3:-Private}" "${4:-dev-key}"
		return
	fi

	# For other secrets, prompt for value if not provided
	if [[ -z $value ]]; then
		read -rsp "Enter value for $key: " value
		echo ""
	fi

	local vault="${3:-Private}"
	set_secret "$key" "$value" "$vault"
}

cmd_run() {
	if [[ $# -eq 0 ]]; then
		log_error "Usage: $0 run <command> [args...]"
		exit 1
	fi

	# Create temporary env file with secret references
	local temp_env
	temp_env=$(mktemp)
	cat >"$temp_env" <<EOF
CACHIX_AUTH_TOKEN=op://Private/cachix-auth-token/credential
GITHUB_TOKEN=op://Private/github-token/credential
EOF

	# Run with environment injection
	env_run "$temp_env" "$@"
	local exit_code=$?
	rm -f "$temp_env"
	return $exit_code
}

cmd_env() {
	local env_file="${1:-}"
	if [[ -z $env_file ]]; then
		log_error "Usage: $0 env <env-file> <command> [args...]"
		exit 1
	fi

	shift
	env_run "$env_file" "$@"
}

cmd_help() {
	cat <<EOF
Usage: $0 [COMMAND] [OPTIONS]

Unified secrets management using 1Password

COMMANDS:
  status              Show secrets management status
  get <key> [vault]   Get a secret value
  set <key> [vault]   Set a secret (will prompt for value)
  run <cmd>           Run command with common secrets injected
  env <file> <cmd>    Run command with custom env file
  help                Show this help

SPECIAL KEYS:
  cachix-token        Cachix authentication token
  github-token        GitHub personal access token
  ssh-key             Generate new SSH key in 1Password

EXAMPLES:
  $0 status                    # Check system status
  $0 get cachix-token         # Get Cachix token
  $0 set github-token         # Set GitHub token (will prompt)
  $0 set ssh-key Private work  # Generate SSH key named 'work'
  $0 run nix build            # Run with secrets injected
  $0 env .env npm test        # Run with custom env file

ENVIRONMENT:
  Secrets are injected as environment variables using 1Password references.
  Format: op://vault/item/field
  
  Default template at: ~/.config/secrets/template.env
EOF
}

# --- Main Execution -----------------------------------------------------------
main() {
	local cmd="${1:-help}"

	# Allow help command without checking dependencies
	if [[ $cmd == "help" || $cmd == "--help" || $cmd == "-h" ]]; then
		cmd_help
		return
	fi

	if ! check_dependencies; then
		exit 1
	fi

	case "$cmd" in
	status)
		cmd_status
		;;
	get)
		shift
		cmd_get "$@"
		;;
	set)
		shift
		cmd_set "$@"
		;;
	run)
		shift
		cmd_run "$@"
		;;
	env)
		shift
		cmd_env "$@"
		;;
	help | --help | -h)
		cmd_help
		;;
	*)
		log_error "Unknown command: $cmd"
		cmd_help
		exit 1
		;;
	esac
}

main "$@"
