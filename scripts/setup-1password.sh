#!/usr/bin/env bash
# Title         : setup-1password.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : scripts/setup-1password.sh
# ---------------------------------------
# Interactive 1Password setup wizard for secrets management

set -euo pipefail

# --- Logging Utilities --------------------------------------------------------
log() { echo -e "\033[0;3${2:-4}m[$1]\033[0m ${*:3}"; }
info() { log INFO 4 "$@"; }
ok() { log OK 2 "$@"; }
warn() { log WARN 3 "$@"; }
error() {
  log ERROR 1 "$@" >&2
  exit 1
}

trap 'error "Setup failed at line $LINENO"' ERR

# --- Prerequisites Check ------------------------------------------------------
check_prerequisites() {
  info "Checking prerequisites..."

  # Check if 1Password app is installed
  if [[ -d "/Applications/1Password.app" ]] || [[ -d "$HOME/Applications/1Password.app" ]]; then
    ok "1Password app installed"
  else
    error "1Password app not found. Install via: brew install --cask 1password"
  fi

  # Check if 1Password CLI is installed
  if command -v op &>/dev/null; then
    ok "1Password CLI installed: $(op --version 2>/dev/null || echo 'version check failed')"
  else
    error "1Password CLI not found. It should be installed via Nix packages"
  fi

  # Check SSH agent socket
  local socket_path="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  if [[ -S $socket_path ]]; then
    ok "1Password SSH agent socket found"
  else
    warn "SSH agent socket not found. Enable in 1Password app: Settings → Developer → SSH Agent"
  fi
}

# --- 1Password Sign In -------------------------------------------------------
setup_signin() {
  info "Checking 1Password authentication..."

  if op account list &>/dev/null 2>&1; then
    ok "Already signed in to 1Password"
    return
  fi

  info "Please sign in to 1Password CLI..."
  echo ""
  echo "Run: op signin"
  echo ""
  echo "Follow the prompts to authenticate with your 1Password account."
  echo "After signing in, run this script again."
  exit 0
}

# --- Setup Core Secrets -------------------------------------------------------
setup_secrets() {
  info "Setting up core secrets..."

  # Check Cachix token
  if op item get "cachix-auth-token" --vault="Private" &>/dev/null 2>&1; then
    ok "Cachix token already configured"
  else
    warn "Cachix token not found"
    echo ""
    echo "To set up Cachix token:"
    echo "1. Get your token from: https://app.cachix.org/personal-auth-tokens"
    echo "2. Run: secrets-manager set cachix-token"
    echo ""
    read -p "Set up Cachix token now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      secrets-manager set cachix-token
    fi
  fi

  # Check GitHub token
  if op item get "github-token" --vault="Private" &>/dev/null 2>&1; then
    ok "GitHub token already configured"
  else
    warn "GitHub token not found"
    echo ""
    echo "To set up GitHub token:"
    echo "1. Create a token at: https://github.com/settings/tokens"
    echo "2. Scopes needed: repo, workflow, read:packages, write:packages"
    echo "3. Run: secrets-manager set github-token"
    echo ""
    read -p "Set up GitHub token now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      secrets-manager set github-token
    fi
  fi
}

# --- Setup SSH Keys -----------------------------------------------------------
setup_ssh_keys() {
  info "Checking SSH keys..."

  local ssh_count
  ssh_count=$(op item list --categories="SSH Key" --vault="Private" --format=json 2>/dev/null | jq length 2>/dev/null || echo 0)

  if [[ $ssh_count -gt 0 ]]; then
    ok "Found $ssh_count SSH key(s) in 1Password"
    op item list --categories="SSH Key" --vault="Private" --format=json 2>/dev/null | jq -r '.[].title' 2>/dev/null | while read -r key; do
      echo "  - $key"
    done
  else
    warn "No SSH keys found in 1Password"
    echo ""
    echo "To generate an SSH key in 1Password:"
    echo "Run: secrets-manager set ssh-key Private <key-name>"
    echo ""
    echo "Example: secrets-manager set ssh-key Private github-key"
    echo ""
    read -p "Generate a default SSH key now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      secrets-manager set ssh-key Private default-key
    fi
  fi
}

# --- Configure Git Signing ----------------------------------------------------
setup_git_signing() {
  info "Checking Git commit signing..."

  local current_key
  current_key=$(git config --global user.signingkey 2>/dev/null || echo "")

  if [[ -n $current_key ]]; then
    ok "Git signing key configured: ${current_key:0:16}..."
  else
    warn "Git signing not configured"
    echo ""
    echo "To enable Git commit signing with 1Password:"
    echo "1. In 1Password app: Settings → Developer → Git Commit Signing"
    echo "2. Follow the setup instructions"
    echo "3. Your commits will be automatically signed"
  fi
}

# --- Verify Environment -------------------------------------------------------
verify_setup() {
  info "Verifying setup..."
  echo ""

  # Run status check
  secrets-manager status

  echo ""
  ok "1Password setup complete!"
  echo ""
  echo "Quick reference:"
  echo "  secrets-manager status     # Check status"
  echo "  secrets-manager get <key>  # Get a secret"
  echo "  secrets-manager set <key>  # Set a secret"
  echo "  secrets-manager run <cmd>  # Run with secrets"
  echo ""
  echo "SSH usage:"
  echo "  SSH keys are automatically available via 1Password SSH agent"
  echo "  Socket: ~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  echo ""
  echo "Template environment file: ~/.config/secrets/template.env"
}

# --- Main Execution -----------------------------------------------------------
main() {
  echo "🔐 1Password Setup for Dotfiles"
  echo "================================"
  echo ""

  check_prerequisites
  setup_signin
  setup_secrets
  setup_ssh_keys
  setup_git_signing
  verify_setup
}

main "$@"
