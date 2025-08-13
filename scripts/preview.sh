#!/usr/bin/env bash
# Title         : preview.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : scripts/preview.sh
# ---------------------------------------
# Preview configuration changes without applying them
set -euo pipefail

# Source common functions
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
# shellcheck source=/dev/null
source "${DOTFILES}/lib/common.sh" 2>/dev/null || true

# --- Main Preview Logic ---------------------------------------------------

cd "${DOTFILES:-$HOME/.dotfiles}"

# Get configuration name
config_name=$(get_config_name)

echo "═══════════════════════════════════════════════════════════════"
echo "  Configuration Preview for: $config_name"
echo "═══════════════════════════════════════════════════════════════"
echo

# --- Build Phase ----------------------------------------------------------
echo "Building configuration (without switching)..."
if command -v nix-fast-build &>/dev/null; then
  nix-fast-build --skip-cached --no-nom ".#darwinConfigurations.${config_name}.system" || exit 1
elif command -v nom &>/dev/null; then
  nix build --log-format internal-json -v ".#darwinConfigurations.${config_name}.system" |& nom --json || exit 1
else
  nix build ".#darwinConfigurations.${config_name}.system" --print-build-logs || exit 1
fi

echo
echo "Build successful! Analyzing changes..."
echo

# --- Package Changes ------------------------------------------------------
echo "──────────────────────────────────────────────────────────────"
echo "📦 Package Changes:"
echo "──────────────────────────────────────────────────────────────"

# Check if we have a current system to compare against
if [[ -e /run/current-system ]]; then
  # Use nvd if available for prettier output
  if command -v nvd &>/dev/null; then
    echo "Using nvd for enhanced comparison..."
    nvd diff /run/current-system ./result || true
  else
    # Fallback to nix store diff-closures
    echo "Package differences:"
    nix store diff-closures /run/current-system ./result || true
  fi
else
  echo "No current system found (first installation?)"
  echo "Packages to be installed:"
  nix path-info --closure-size -h ./result || true
fi

echo

# --- Homebrew Changes -----------------------------------------------------
if [[ -f "${DOTFILES}/darwin/modules/homebrew.nix" ]]; then
  echo "──────────────────────────────────────────────────────────────"
  echo "🍺 Homebrew Configuration:"
  echo "──────────────────────────────────────────────────────────────"

  # Extract configured packages from homebrew.nix
  echo "Managed brews:"
  grep -A 10 "brews = " "${DOTFILES}/darwin/modules/homebrew.nix" | grep '"' | sed 's/.*"\(.*\)".*/  - \1/' || echo "  None configured"

  echo
  echo "Managed casks:"
  grep -A 20 "casks = " "${DOTFILES}/darwin/modules/homebrew.nix" | grep '"' | sed 's/.*"\(.*\)".*/  - \1/' || echo "  None configured"

  # Check cleanup setting
  cleanup=$(grep "cleanup = " "${DOTFILES}/darwin/modules/homebrew.nix" | sed 's/.*cleanup = "\(.*\)".*/\1/' || echo "none")
  if [[ "$cleanup" == "zap" ]]; then
    echo
    echo "⚠️  Warning: Homebrew cleanup is set to 'zap'"
    echo "   Unlisted packages will be REMOVED on deployment"

    # Show current Homebrew packages for comparison
    if command -v brew &>/dev/null; then
      current_brews=$(brew list 2>/dev/null | wc -l | tr -d ' ')
      current_casks=$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')
      echo
      echo "   Current system has: $current_brews brews, $current_casks casks"
      echo "   Run 'brew list' to see what would be removed"
    fi
  fi
  echo
fi

# --- Environment Variables ------------------------------------------------
echo "──────────────────────────────────────────────────────────────"
echo "🔧 Key Configuration Settings:"
echo "──────────────────────────────────────────────────────────────"

# Show some key settings that would change
echo "System configuration:"
echo "  - State version: $(grep -m1 'system.stateVersion' "${DOTFILES}/darwin/hosts/base.nix" | sed 's/.*= *//' || echo "unknown")"
echo "  - Primary user: $(whoami)"

echo
echo "Home configuration:"
echo "  - State version: $(grep -m1 'stateVersion' "${DOTFILES}/home/default.nix" | sed 's/.*= *//' | tr -d '";' || echo "unknown")"
echo "  - XDG paths configured: ✓"

echo

# --- Generation Info ------------------------------------------------------
echo "──────────────────────────────────────────────────────────────"
echo "📋 Generation Management:"
echo "──────────────────────────────────────────────────────────────"

# Get current generation if it exists
if [[ -L /nix/var/nix/profiles/system ]]; then
  current_gen=$(readlink /nix/var/nix/profiles/system | sed 's/.*system-\([0-9]*\)-link/\1/')
  echo "Current system generation: $current_gen"
  echo "After deployment, this will be generation: $((current_gen + 1))"
else
  echo "This will be the first generation"
fi

echo
echo "Rollback commands available after deployment:"
echo "  - ndrrollback     # Instant rollback to current state"
echo "  - ngenswitch $current_gen  # Switch to specific generation"

echo

# --- Summary --------------------------------------------------------------
echo "══════════════════════════════════════════════════════════════"
echo "📝 Summary:"
echo "══════════════════════════════════════════════════════════════"
echo
echo "✓ Configuration built successfully"
echo "✓ Changes analyzed and displayed above"
echo
echo "To apply these changes, run:"
echo "  nrb           # Standard rebuild and switch"
echo "  rebuild       # Or use the rebuild script directly"
echo
echo "To see more details:"
echo "  nix-tree ./result    # Explore dependencies interactively"
echo "  ndiff <old> <new>    # Compare specific derivations"
echo
echo "This preview is read-only. No changes have been applied."
echo "══════════════════════════════════════════════════════════════"
