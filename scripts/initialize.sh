#!/usr/bin/env bash
# Title         : initialize.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : scripts/initialize.sh
# ---------------------------------------
# Set environment variables for dotfiles configuration

set -euo pipefail

echo "Dotfiles Environment Initialization"
echo "===================================="
echo

# Get system information automatically
DOTFILES_USERNAME="$(whoami)"
export DOTFILES_USERNAME
DOTFILES_SYSTEM="$(uname -m)"
export DOTFILES_SYSTEM

# Convert to Nix system format
case "$DOTFILES_SYSTEM" in
    arm64)
        export DOTFILES_SYSTEM="aarch64-darwin"
        ;;
    x86_64)
        export DOTFILES_SYSTEM="x86_64-darwin"
        ;;
    *)
        echo "Warning: Unknown system architecture: $DOTFILES_SYSTEM"
        export DOTFILES_SYSTEM="aarch64-darwin"
        ;;
esac

echo "Detected Configuration:"
echo "  Username: $DOTFILES_USERNAME"
echo "  System: $DOTFILES_SYSTEM"
echo

# Ask for Git configuration
echo -n "Enter your Git username: "
read -r git_user
echo -n "Enter your Git email: "
read -r git_email

export DOTFILES_GIT_USERNAME="$git_user"
export DOTFILES_GIT_EMAIL="$git_email"

echo
echo "Environment variables set:"
echo "  DOTFILES_USERNAME=$DOTFILES_USERNAME"
echo "  DOTFILES_SYSTEM=$DOTFILES_SYSTEM"
echo "  DOTFILES_GIT_USERNAME=$DOTFILES_GIT_USERNAME"
echo "  DOTFILES_GIT_EMAIL=$DOTFILES_GIT_EMAIL"
echo
echo "Configuration complete. These variables are now available in this shell session."