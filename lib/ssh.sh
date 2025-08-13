#!/usr/bin/env bash
# Title         : ssh.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : lib/ssh.sh
# ---------------------------------------
# SSH utility functions for 1Password integration
# Used by ssh-setup.sh and other scripts

# --- SSH Agent Detection ------------------------------------------------------

# Get the correct 1Password socket path for the current platform
get_1password_socket_path() {
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  else
    echo "$HOME/.1password/agent.sock"
  fi
}

# Check if 1Password SSH agent is available and working
is_1password_ssh_agent_available() {
  local socket_path
  socket_path=$(get_1password_socket_path)
  [[ -S $socket_path ]] || return 1
  SSH_AUTH_SOCK="$socket_path" ssh-add -l &>/dev/null 2>&1
}

# Check if 1Password CLI is available and authenticated
is_1password_cli_available() {
  command -v op &>/dev/null || return 1
  op account list &>/dev/null 2>&1
}

# Get the appropriate SSH_AUTH_SOCK value
get_ssh_auth_sock() {
  local onepass_socket
  onepass_socket=$(get_1password_socket_path)

  if [[ -S $onepass_socket ]]; then
    echo "$onepass_socket"
    return 0
  elif [[ -n ${SSH_AUTH_SOCK:-} && -S $SSH_AUTH_SOCK ]]; then
    echo "$SSH_AUTH_SOCK"
    return 0
  fi

  return 1
}

# --- SSH Key Information ------------------------------------------------------

# Check if SSH keys exist in 1Password
has_ssh_keys() {
  if is_1password_cli_available; then
    op item list --categories "SSH Key" --format json 2>/dev/null | jq -e '. | length > 0' &>/dev/null && return 0
  fi

  return 1
}

# Get the primary SSH key name/identifier from 1Password
get_primary_ssh_key_id() {
  if is_1password_cli_available; then
    local first_key
    first_key=$(op item list --categories "SSH Key" --format json 2>/dev/null | jq -r '.[0].title' 2>/dev/null)
    if [[ -n $first_key && $first_key != "null" ]]; then
      echo "$first_key"
      return 0
    fi
  fi

  return 1
}

# Get public key content by ID from 1Password
get_ssh_public_key() {
  local key_id="$1"

  if is_1password_cli_available; then
    op item get "$key_id" --fields "public key" 2>/dev/null
  else
    return 1
  fi
}

# --- SSH Environment Setup ----------------------------------------------------

# Setup SSH environment to use 1Password
setup_ssh_environment() {
  local socket_path
  socket_path=$(get_1password_socket_path)

  if [[ -S $socket_path ]]; then
    export SSH_AUTH_SOCK="$socket_path"
    echo "SSH agent configured to use 1Password"
    return 0
  else
    echo "1Password SSH agent not available"
    return 1
  fi
}

# Get SSH agent status
get_ssh_agent_status() {
  local socket_path
  socket_path=$(get_1password_socket_path)

  if [[ -S $socket_path ]]; then
    if SSH_AUTH_SOCK="$socket_path" ssh-add -l &>/dev/null 2>&1; then
      echo "1Password SSH agent: Active"
      echo "Socket: $socket_path"
      echo "Keys available: $(SSH_AUTH_SOCK="$socket_path" ssh-add -l 2>/dev/null | wc -l | tr -d ' ')"
    else
      echo "1Password SSH agent: Socket exists but no keys"
    fi
  else
    echo "1Password SSH agent: Not configured"
    echo "Enable in 1Password app: Settings → Developer → SSH Agent"
  fi
}

# --- Git Integration ----------------------------------------------------------

# Configure Git to use SSH signing with 1Password
setup_git_ssh_signing() {
  if ! is_1password_cli_available; then
    echo "1Password CLI not available"
    return 1
  fi

  local key_id
  key_id=$(get_primary_ssh_key_id)

  if [[ -n $key_id ]]; then
    local pub_key
    pub_key=$(get_ssh_public_key "$key_id")

    if [[ -n $pub_key ]]; then
      # Configure Git for SSH signing
      git config --global gpg.format ssh
      git config --global user.signingkey "$pub_key"
      git config --global commit.gpgsign true

      echo "Git configured for SSH signing with 1Password key: $key_id"
      return 0
    fi
  fi

  echo "No SSH keys found in 1Password for Git signing"
  return 1
}
