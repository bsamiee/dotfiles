#!/usr/bin/env bash
# Title         : rebuild.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : scripts/rebuild.sh
# ---------------------------------------
# Consolidated rebuild script for nix-darwin with update and build options

set -euo pipefail

# Source common functions
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
# shellcheck source=/dev/null
source "${DOTFILES}/lib/common.sh" 2>/dev/null || true

# --- Usage and Help ---
usage() {
	cat <<EOF
Usage: $0 [OPTIONS] [darwin-rebuild-args]

OPTIONS:
  -u, --update     Update flake inputs before building
  -c, --check      Run flake check before building
  -n, --no-switch  Build only, don't switch to new configuration
  -d, --diff       Show detailed package differences after build
  -p, --preview    Build and preview changes (implies -n and -d)
  -h, --help       Show this help message

darwin-rebuild-args:
  Any additional arguments are passed to darwin-rebuild (e.g., switch, build, rollback)

EXAMPLES:
  $0                    # Build and switch to new configuration
  $0 -u                 # Update flake inputs, then build and switch
  $0 -c                 # Check flake, then build and switch
  $0 -n                 # Build only, don't switch
  $0 -d                 # Build, switch, and show differences
  $0 -p                 # Preview changes without switching
  $0 rollback           # Pass 'rollback' to darwin-rebuild
EOF
	exit 0
}

# --- Parse Arguments ---
UPDATE_FLAKE=false
CHECK_FLAKE=false
NO_SWITCH=false
SHOW_DIFF=false
PREVIEW_MODE=false
DARWIN_ARGS=()

while [[ $# -gt 0 ]]; do
	case "$1" in
	-u | --update)
		UPDATE_FLAKE=true
		shift
		;;
	-c | --check)
		CHECK_FLAKE=true
		shift
		;;
	-n | --no-switch)
		NO_SWITCH=true
		shift
		;;
	-d | --diff)
		SHOW_DIFF=true
		shift
		;;
	-p | --preview)
		PREVIEW_MODE=true
		NO_SWITCH=true
		SHOW_DIFF=true
		shift
		;;
	-h | --help)
		usage
		;;
	*)
		DARWIN_ARGS+=("$1")
		shift
		;;
	esac
done

# Default to 'switch' if no darwin-rebuild command specified and not no-switch
if [[ ${#DARWIN_ARGS[@]} -eq 0 ]] && [[ $NO_SWITCH == false ]]; then
	DARWIN_ARGS=("switch")
fi

# --- Main Script ---
cd "${DOTFILES:-$HOME/.dotfiles}"

# Ensure cache is available for faster builds (non-blocking)
if command -v cachix &>/dev/null 2>&1; then
	if ! cachix authtoken &>/dev/null 2>&1; then
		# Try unified secrets manager first (1Password)
		if command -v secrets-manager &>/dev/null; then
			if TOKEN=$(secrets-manager get cachix-token 2>/dev/null); then
				echo "Setting up Cachix from 1Password..."
				echo "$TOKEN" | cachix authtoken --stdin &>/dev/null 2>&1 || true
			fi
		# Try environment variable
		elif [ -n "${CACHIX_AUTH_TOKEN:-}" ]; then
			echo "Setting up Cachix from environment..."
			echo "$CACHIX_AUTH_TOKEN" | cachix authtoken --stdin &>/dev/null 2>&1 || true
		# Try macOS keychain (legacy)
		elif [[ $OSTYPE == "darwin"* ]]; then
			TOKEN=$(security find-generic-password -a "$USER" -s "cachix-auth-token" -w 2>/dev/null || true)
			if [ -n "$TOKEN" ]; then
				echo "Setting up Cachix from keychain..."
				echo "$TOKEN" | cachix authtoken --stdin &>/dev/null 2>&1 || true
			fi
		fi
	fi
	# Report cache status (only if authenticated)
	cachix authtoken &>/dev/null 2>&1 && echo "✓ Cache enabled (faster builds)"
fi

# Get universal system variables
config_name=$(get_config_name)
start_time=$(date +%s)

show_system_info

# Update flake if requested
if [[ $UPDATE_FLAKE == true ]]; then
	echo "Checking for uncommitted changes..."
	if [[ -n "$(git status --porcelain)" ]]; then
		echo "Warning: Uncommitted changes detected. Consider committing or stashing first."
		read -p "Continue anyway? (y/N) " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			exit 1
		fi
	fi

	echo "Updating flake inputs..."
	nix flake update --commit-lock-file
fi

# Check flake if requested
if [[ $CHECK_FLAKE == true ]]; then
	echo "Checking flake..."
	nix flake check --no-build
fi

# Build phase with intelligent tool selection
echo "Building '$config_name' configuration..."

# Always use --impure since we're reading environment variables
if command -v nix-fast-build &>/dev/null; then
	echo "Using nix-fast-build for enhanced performance..."
	nix-fast-build --impure --skip-cached --no-nom ".#darwinConfigurations.${config_name}.system" || exit 1
elif command -v nom &>/dev/null; then
	echo "Using nom for enhanced output..."
	nix build --impure --log-format internal-json -v ".#darwinConfigurations.${config_name}.system" |& nom --json || exit 1
else
	nix build --impure ".#darwinConfigurations.${config_name}.system" --print-build-logs || exit 1
fi

# Show diff if requested (before or after switch)
if [[ $SHOW_DIFF == true ]]; then
	echo
	echo "──────────────────────────────────────────────────────────────"
	echo "Analyzing changes..."
	echo "──────────────────────────────────────────────────────────────"

	# If we have a current system, show the diff
	if [[ -e /run/current-system ]]; then
		if command -v nvd &>/dev/null; then
			nvd diff /run/current-system ./result || true
		else
			nix store diff-closures /run/current-system ./result || true
		fi
	else
		echo "No current system found (first installation?)"
		nix path-info --closure-size -h ./result || true
	fi
	echo
fi

# Apply configuration if not no-switch
if [[ $NO_SWITCH == false ]] && [[ ${#DARWIN_ARGS[@]} -gt 0 ]]; then
	echo "Applying configuration (${DARWIN_ARGS[*]})..."
	sudo --preserve-env=HOME ./result/sw/bin/darwin-rebuild "${DARWIN_ARGS[@]}" --flake ".#${config_name}"
fi

# Preview mode message
if [[ $PREVIEW_MODE == true ]]; then
	echo
	echo "──────────────────────────────────────────────────────────────"
	echo "Preview complete. No changes have been applied."
	echo "To apply these changes, run: nrb"
	echo "──────────────────────────────────────────────────────────────"
fi

# Calculate and display duration
end_time=$(date +%s)
duration=$((end_time - start_time))
duration_msg="Operation completed in $duration seconds"

echo "$duration_msg"

# Send notification if terminal-notifier is available
if command -v terminal-notifier &>/dev/null; then
	terminal-notifier -title "Darwin Rebuild" \
		-subtitle "${config_name} configuration (${DARWIN_ARGS[*]:-build})" \
		-message "$duration_msg" \
		-group "darwin-rebuild" &>/dev/null &
fi

# Success message
if [[ $UPDATE_FLAKE == true ]]; then
	echo "✓ Flake inputs updated"
fi
if [[ $CHECK_FLAKE == true ]]; then
	echo "✓ Flake check passed"
fi
echo "✓ Build complete"
if [[ $NO_SWITCH == false ]] && [[ ${#DARWIN_ARGS[@]} -gt 0 ]]; then
	echo "✓ Configuration applied"

	# Warm cache with new build in background (non-blocking)
	if cachix authtoken &>/dev/null 2>&1; then
		(cachix-manager warm darwin &>/dev/null 2>&1 &) || true
	fi
fi
