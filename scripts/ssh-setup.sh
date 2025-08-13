#!/usr/bin/env bash
# Title         : ssh-setup.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : scripts/ssh-setup.sh
# ---------------------------------------
# SSH key management with 1Password integration and Git signing setup

set -euo pipefail

# --- Configuration & Globals --------------------------------------------------
readonly SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_ROOT
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly SSH_DIR="$HOME/.ssh"
readonly GIT_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/git"

# Source common utilities
# shellcheck disable=SC1091  # Common utilities - sourcing expected here
source "$DOTFILES_ROOT/lib/common.sh"

# --- Logging Utilities --------------------------------------------------------
log() { echo -e "\033[0;3${2:-4}m[$1]\033[0m ${*:3}"; }
info() { log INFO 4 "$@"; }
ok() { log OK 2 "$@"; }
warn() { log WARN 3 "$@"; }
error() {
  log ERROR 1 "$@" >&2
  exit 1
}

# --- 1Password Availability Checks --------------------------------------------
check_1password_cli() {
  command -v op &>/dev/null || return 1
  op account list &>/dev/null 2>&1 || return 1
  return 0
}

check_1password_ssh_agent() {
  # Source SSH utilities for socket path detection
  # shellcheck disable=SC1091  # SSH utilities - sourcing expected here
  source "$DOTFILES_ROOT/lib/ssh.sh" 2>/dev/null || {
    warn "SSH utilities not available"
    return 1
  }

  local socket_path
  socket_path=$(get_1password_socket_path)
  [[ -S $socket_path ]] || return 1
  SSH_AUTH_SOCK="$socket_path" ssh-add -l &>/dev/null 2>&1 || return 1
  return 0
}

validate_ssh_agent() {
  if ! check_1password_ssh_agent; then
    warn "1Password SSH agent not available"
    warn "Ensure 1Password is running and SSH agent is enabled"
    return 1
  fi
  return 0
}

# --- SSH Key Discovery --------------------------------------------------------
discover_ssh_keys() {
  local keys=()

  if ! check_1password_cli; then
    warn "1Password CLI not available - cannot discover SSH keys"
    return 1
  fi

  info "Discovering SSH keys in 1Password..."

  # List SSH keys using the 1Password CLI
  local key_items
  key_items=$(op item list --categories "SSH Key" --format json 2>/dev/null) || {
    warn "Failed to list SSH keys from 1Password"
    return 1
  }

  if [[ -z $key_items || $key_items == "[]" ]]; then
    warn "No SSH keys found in 1Password"
    return 1
  fi

  # Parse key names and IDs
  local key_names
  key_names=$(echo "$key_items" | jq -r '.[].title' 2>/dev/null) || {
    warn "Failed to parse SSH key list"
    return 1
  }

  if [[ -z $key_names ]]; then
    warn "No SSH key names found"
    return 1
  fi

  ok "Found SSH keys in 1Password:"
  while IFS= read -r key_name; do
    echo "  • $key_name"
    keys+=("$key_name")
  done <<<"$key_names"

  # Return the keys array (caller should use: readarray -t keys < <(discover_ssh_keys))
  printf '%s\n' "${keys[@]}"
  return 0
}

get_primary_ssh_key() {
  local keys

  # Try to discover keys from 1Password first
  if keys=$(discover_ssh_keys 2>/dev/null); then
    # Use the first SSH key as primary
    echo "$keys" | head -1
    return 0
  fi

  # Fallback to local SSH keys
  if [[ -f "$SSH_DIR/id_ed25519.pub" ]]; then
    echo "local:id_ed25519"
    return 0
  elif [[ -f "$SSH_DIR/id_rsa.pub" ]]; then
    echo "local:id_rsa"
    return 0
  fi

  warn "No SSH keys found (1Password or local)"
  return 1
}

get_public_key() {
  local key_name="$1"

  if [[ $key_name == local:* ]]; then
    # Handle local keys
    local key_file="${key_name#local:}"
    [[ -f "$SSH_DIR/${key_file}.pub" ]] || return 1
    cat "$SSH_DIR/${key_file}.pub"
    return 0
  fi

  # Handle 1Password keys
  if ! check_1password_cli; then
    warn "1Password CLI not available"
    return 1
  fi

  # Get public key from 1Password
  op item get "$key_name" --fields label=public_key 2>/dev/null || {
    warn "Failed to retrieve public key for: $key_name"
    return 1
  }
}

get_ssh_key_email() {
  local public_key="$1"

  # Extract email from SSH public key comment
  echo "$public_key" | awk '{print $3}' | grep -E '^[^@]+@[^@]+\.[^@]+$' || {
    # Fallback to user's configured Git email
    echo "$(get_username)@$(hostname -s).local"
  }
}

get_ssh_key_fingerprint() {
  local public_key="$1"

  # Generate SSH key fingerprint
  echo "$public_key" | ssh-keygen -lf - 2>/dev/null | awk '{print $2}' || {
    warn "Failed to generate fingerprint"
    return 1
  }
}

# --- Git Signing Configuration ------------------------------------------------
setup_git_signing() {
  info "Setting up Git SSH signing..."

  local primary_key
  primary_key=$(get_primary_ssh_key) || {
    warn "No SSH keys available for Git signing"
    return 1
  }

  local public_key
  public_key=$(get_public_key "$primary_key") || {
    warn "Failed to retrieve public key for Git signing"
    return 1
  }

  local key_email
  key_email=$(get_ssh_key_email "$public_key")

  local git_email
  git_email=$(git config --global user.email 2>/dev/null || echo "$key_email")

  # Create git config directory
  mkdir -p "$GIT_CONFIG_DIR"

  # Update allowed signers file
  update_allowed_signers "$git_email" "$public_key"

  # Configure Git for SSH signing
  git config --global gpg.format ssh
  git config --global user.signingkey "$public_key"
  git config --global gpg.ssh.allowedSignersFile "$GIT_CONFIG_DIR/allowed_signers"
  git config --global commit.gpgsign true
  git config --global tag.gpgsign true

  ok "Git SSH signing configured:"
  echo "  • Signing key: $(get_ssh_key_fingerprint "$public_key")"
  echo "  • Email: $git_email"
  echo "  • Allowed signers: $GIT_CONFIG_DIR/allowed_signers"

  return 0
}

update_allowed_signers() {
  local email="$1"
  local public_key="$2"
  local allowed_signers="$GIT_CONFIG_DIR/allowed_signers"

  info "Updating allowed signers file..."

  # Create directory if it doesn't exist
  mkdir -p "$GIT_CONFIG_DIR"

  # Create temporary file for new allowed signers
  local temp_file
  temp_file=$(mktemp) || {
    error "Failed to create temporary file"
  }

  # Add header if file doesn't exist
  if [[ ! -f $allowed_signers ]]; then
    cat >"$temp_file" <<EOF
# Git SSH Allowed Signers
# Auto-generated by ssh-setup.sh
# Email format: email ssh-key-type base64-key [comment]
EOF
  else
    # Preserve existing content, removing old entries for this email
    grep -v "^$email " "$allowed_signers" >"$temp_file" 2>/dev/null || true
  fi

  # Add the new signing key
  echo "$email $public_key" >>"$temp_file"

  # Atomically replace the allowed signers file
  mv "$temp_file" "$allowed_signers" || {
    rm -f "$temp_file"
    error "Failed to update allowed signers file"
  }

  ok "Updated allowed signers: $allowed_signers"
}

setup_all_git_signers() {
  info "Setting up all SSH keys as Git signers..."

  local keys
  if ! keys=$(discover_ssh_keys 2>/dev/null); then
    warn "No SSH keys found in 1Password for Git signing"
    return 1
  fi

  local git_email
  git_email=$(git config --global user.email 2>/dev/null || echo "$(get_username)@$(hostname -s).local")

  # Process each key
  while IFS= read -r key_name; do
    [[ -n $key_name ]] || continue

    info "Processing SSH key: $key_name"

    local public_key
    public_key=$(get_public_key "$key_name") || {
      warn "Failed to retrieve public key for: $key_name"
      continue
    }

    local key_email
    key_email=$(get_ssh_key_email "$public_key")

    # Use the key's email if available, otherwise use Git email
    local signer_email="${key_email:-$git_email}"

    update_allowed_signers "$signer_email" "$public_key"
  done <<<"$keys"

  # Set up the primary key for signing
  setup_git_signing

  return 0
}

# --- SSH Configuration Management ---------------------------------------------
setup_ssh_config() {
  info "Setting up SSH configuration for 1Password..."

  # Source SSH utilities for socket path detection
  # shellcheck disable=SC1091  # SSH utilities - sourcing expected here
  source "$DOTFILES_ROOT/lib/ssh.sh" 2>/dev/null || {
    warn "SSH utilities not available"
    return 1
  }

  local ssh_config="$SSH_DIR/config"

  # Create SSH directory
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"

  # Create or update SSH config for 1Password agent
  if [[ ! -f $ssh_config ]]; then
    # Get the correct socket path for the current platform
    local socket_path
    socket_path=$(get_1password_socket_path)

    cat >"$ssh_config" <<EOF
# SSH Configuration - Auto-managed by dotfiles
# 1Password SSH Agent Integration
Host *
    IdentityAgent "$socket_path"
    AddKeysToAgent yes
    UseKeychain yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
    chmod 600 "$ssh_config"
    ok "Created SSH config: $ssh_config"
  else
    # Update existing config if needed
    local socket_path
    socket_path=$(get_1password_socket_path)
    if ! grep -q "IdentityAgent.*$(basename "$socket_path")" "$ssh_config" 2>/dev/null; then
      warn "SSH config exists but doesn't include correct 1Password agent settings"
      warn "Expected socket: $socket_path"
      warn "You may want to manually update IdentityAgent configuration"
    else
      ok "SSH config already includes 1Password settings"
    fi
  fi
}

# --- Fallback SSH Key Generation ----------------------------------------------
generate_fallback_ssh_key() {
  local email="${1:-$(get_username)@$(hostname -s).local}"

  info "Generating fallback SSH key..."
  warn "1Password not available - creating local SSH key"

  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"

  # Generate Ed25519 key
  ssh-keygen -t ed25519 -C "$email" -f "$SSH_DIR/id_ed25519" -N "" -q || {
    error "Failed to generate SSH key"
  }

  chmod 600 "$SSH_DIR/id_ed25519"
  chmod 644 "$SSH_DIR/id_ed25519.pub"

  ok "SSH key generated:"
  echo "  • Private key: $SSH_DIR/id_ed25519"
  echo "  • Public key: $SSH_DIR/id_ed25519.pub"
  echo
  echo "Public key content:"
  cat "$SSH_DIR/id_ed25519.pub"
  echo

  # Set up Git signing with local key
  setup_git_signing
}

# --- Deploy-rs Compatibility Validation ---------------------------------------
validate_deploy_rs() {
  info "Validating deploy-rs compatibility..."

  # Check if SSH agent is working
  if ! validate_ssh_agent; then
    warn "Deploy-rs may fail without working SSH agent"
    return 1
  fi

  # Check if we can list identities
  local identities
  local socket_path
  socket_path=$(get_1password_socket_path)
  if identities=$(SSH_AUTH_SOCK="$socket_path" ssh-add -l 2>/dev/null); then
    ok "SSH identities available for deploy-rs:"
    echo "$identities" | while read -r line; do
      echo "  • $line"
    done
  else
    warn "No SSH identities available for deploy-rs"
    return 1
  fi

  # Check Git signing configuration
  if git config --global commit.gpgsign >/dev/null 2>&1; then
    ok "Git signing configured for deploy-rs commits"
  else
    warn "Git signing not configured - deploy-rs commits won't be signed"
  fi

  return 0
}

# --- Health Checks ------------------------------------------------------------
health_check() {
  info "Running SSH health check..."

  local errors=0

  # Check 1Password CLI
  if check_1password_cli; then
    ok "1Password CLI: Available and authenticated"
  else
    warn "1Password CLI: Not available or not authenticated"
    ((errors++))
  fi

  # Check 1Password SSH agent
  if check_1password_ssh_agent; then
    ok "1Password SSH agent: Running"
  else
    warn "1Password SSH agent: Not running"
    ((errors++))
  fi

  # Check SSH keys
  local primary_key
  if primary_key=$(get_primary_ssh_key 2>/dev/null); then
    ok "Primary SSH key: $primary_key"
  else
    warn "Primary SSH key: Not found"
    ((errors++))
  fi

  # Check Git signing
  if git config --global commit.gpgsign >/dev/null 2>&1; then
    local signing_key
    signing_key=$(git config --global user.signingkey 2>/dev/null || echo "Not set")
    ok "Git signing: Enabled (key: ${signing_key:0:50}...)"
  else
    warn "Git signing: Not configured"
    ((errors++))
  fi

  # Check allowed signers file
  local allowed_signers="$GIT_CONFIG_DIR/allowed_signers"
  if [[ -f $allowed_signers ]]; then
    local signers_count
    signers_count=$(grep -c "^[^#]" "$allowed_signers" 2>/dev/null || echo "0")
    ok "Git allowed signers: $signers_count entries"
  else
    warn "Git allowed signers: File not found"
    ((errors++))
  fi

  # Summary
  echo
  if [[ $errors -eq 0 ]]; then
    ok "SSH health check: All systems operational ✓"
  else
    warn "SSH health check: $errors issues found"
    warn "Run 'ssh-setup.sh setup' to fix issues"
  fi

  return $errors
}

# --- Main Command Interface ---------------------------------------------------
cmd_setup() {
  info "Setting up SSH with 1Password integration..."

  # Check if 1Password is available
  if check_1password_cli && check_1password_ssh_agent; then
    ok "1Password SSH integration available"

    # Set up SSH configuration
    setup_ssh_config

    # Set up Git signing with all SSH keys
    setup_all_git_signers || {
      warn "Failed to set up Git signing - trying basic setup"
      setup_git_signing || warn "Git signing setup failed"
    }

    # Validate deploy-rs compatibility
    validate_deploy_rs || warn "Deploy-rs validation failed"

    ok "SSH setup complete with 1Password integration"

  else
    warn "1Password not available - using fallback SSH key generation"

    # Check if we already have local keys
    if [[ -f "$SSH_DIR/id_ed25519" ]]; then
      ok "Local SSH key already exists"
      setup_git_signing || warn "Git signing setup failed"
    else
      # Generate fallback keys
      local email
      email=$(git config --global user.email 2>/dev/null || echo "")
      [[ -z $email ]] && read -rp "Enter email for SSH key: " email
      [[ -z $email ]] && email="$(get_username)@$(hostname -s).local"

      generate_fallback_ssh_key "$email"
    fi
  fi
}

cmd_update() {
  info "Updating SSH configuration..."

  if check_1password_cli; then
    setup_all_git_signers || {
      warn "Failed to update Git signing configuration"
      return 1
    }
    ok "SSH configuration updated"
  else
    warn "1Password CLI not available - cannot update from 1Password"
    return 1
  fi
}

cmd_validate() {
  validate_deploy_rs
}

cmd_health() {
  health_check
}

cmd_keys() {
  info "Listing available SSH keys..."

  if check_1password_cli; then
    local keys
    if keys=$(discover_ssh_keys 2>/dev/null); then
      ok "SSH keys in 1Password:"
      while IFS= read -r key_name; do
        echo "  • $key_name"

        local public_key
        if public_key=$(get_public_key "$key_name" 2>/dev/null); then
          local fingerprint
          fingerprint=$(get_ssh_key_fingerprint "$public_key" 2>/dev/null || echo "unknown")
          echo "    Fingerprint: $fingerprint"
        fi
      done <<<"$keys"
    else
      warn "No SSH keys found in 1Password"
    fi
  else
    warn "1Password CLI not available"
  fi

  # Also show local keys
  if [[ -f "$SSH_DIR/id_ed25519.pub" ]] || [[ -f "$SSH_DIR/id_rsa.pub" ]]; then
    echo
    ok "Local SSH keys:"
    for key_file in "$SSH_DIR"/id_*.pub; do
      [[ -f $key_file ]] || continue
      local fingerprint
      fingerprint=$(ssh-keygen -lf "$key_file" 2>/dev/null | awk '{print $2}' || echo "unknown")
      echo "  • $(basename "$key_file" .pub): $fingerprint"
    done
  fi
}

# --- Usage and Help -----------------------------------------------------------
usage() {
  cat <<EOF
SSH Setup - 1Password Integration

USAGE:
    ssh-setup.sh <command>

COMMANDS:
    setup       Set up SSH with 1Password integration
    update      Update SSH configuration from 1Password
    validate    Validate deploy-rs compatibility
    health      Run SSH health check
    keys        List available SSH keys
    help        Show this help message

EXAMPLES:
    # Initial setup (run after enabling 1Password SSH agent)
    ssh-setup.sh setup
    
    # Update configuration after adding new SSH keys
    ssh-setup.sh update
    
    # Check system health
    ssh-setup.sh health
    
    # List all available SSH keys
    ssh-setup.sh keys

REQUIREMENTS:
    • 1Password CLI (op) installed and authenticated
    • 1Password SSH agent enabled
    • SSH keys stored in 1Password as "SSH Key" items
    
FALLBACK:
    If 1Password is not available, will generate local SSH keys
    and configure Git signing with those keys instead.
EOF
}

# --- Main Execution -----------------------------------------------------------
main() {
  case "${1:-}" in
    setup) cmd_setup ;;
    update) cmd_update ;;
    validate) cmd_validate ;;
    health) cmd_health ;;
    keys) cmd_keys ;;
    help | --help | -h) usage ;;
    "") usage ;;
    *) error "Unknown command: $1. Use 'help' for usage." ;;
  esac
}

# Run if executed directly
[[ ${BASH_SOURCE[0]} == "${0}" ]] && main "$@"
