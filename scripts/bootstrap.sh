#!/usr/bin/env bash
# Title         : bootstrap.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : scripts/bootstrap.sh
# ---------------------------------------
# macOS bootstrap for nix-darwin and home-manager with Determinate Nix

set -euo pipefail

# --- Configuration & Globals --------------------------------------------------
readonly REPO="${DOTFILES_REPO:-https://github.com/bardiasamiee/.dotfiles.git}"
readonly DOTFILES="${DOTFILES_PATH:-$HOME/.dotfiles}"
readonly MIN_MACOS="12"

# Source SSH utilities (includes sudo helper)
# shellcheck source=/dev/null
source "${DOTFILES}/lib/ssh.sh" 2>/dev/null || true

# --- Logging Utilities --------------------------------------------------------
log() { echo -e "\033[0;3${2:-4}m[$1]\033[0m ${*:3}"; }
info() { log INFO 4 "$@"; }
ok() { log OK 2 "$@"; }
warn() { log WARN 3 "$@"; }
error() {
	log ERROR 1 "$@" >&2
	exit 1
}

trap 'error "Bootstrap failed at line $LINENO"' ERR

# --- Prerequisite Checks ------------------------------------------------------
check_prereqs() {
	info "Checking prerequisites..."

	local version
	version=$(sw_vers -productVersion | cut -d. -f1)
	[[ $version -ge $MIN_MACOS ]] || error "macOS $MIN_MACOS+ required. Found: macOS $version"

	local arch
	arch=$(uname -m)
	info "Detected architecture: $arch"

	if ! command -v git &>/dev/null; then
		info "Installing Command Line Tools..."
		xcode-select --install
		warn "Complete CLI Tools installation and re-run this script"
		exit 0
	fi

	# Install Rosetta 2 for Apple Silicon
	if [[ $arch == "arm64" ]] && ! pgrep -q oahd; then
		info "Installing Rosetta 2 for x86 compatibility..."
		softwareupdate --install-rosetta --agree-to-license &>/dev/null || warn "Rosetta 2 installation failed"
	fi

	ok "Prerequisites validated"
}

# --- Homebrew Note ------------------------------------------------------------
# Homebrew is now installed and managed by nix-homebrew during darwin-rebuild
# The nix-homebrew module handles installation, Rosetta setup, and management
# See: flake/systems.nix for nix-homebrew configuration

# --- Nix Installation ---------------------------------------------------------
install_nix() {
	command -v nix &>/dev/null && {
		ok "Nix already installed: $(nix --version 2>/dev/null | head -1)"
		configure_trusted_user
		return
	}

	info "Installing Determinate Nix..."
	curl -fsSL https://install.determinate.systems/nix |
		sh -s -- install --determinate --no-confirm

	set +u
	# shellcheck disable=SC1091  # External Nix daemon profile - sourcing expected here
	. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true
	set -u

	# Restart shell environment to pick up Nix
	info "Refreshing shell environment..."
	export PATH="/nix/var/nix/profiles/default/bin:$PATH"

	# Source Nix daemon for proper environment
	if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
		# shellcheck source=/dev/null
		source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
	fi

	# Configure current user as trusted user
	configure_trusted_user

	ok "Nix installation complete"
}

# --- Nix Trusted User Configuration -------------------------------------------
configure_trusted_user() {
	local username
	username=$(whoami)
	local nix_conf="/etc/nix/nix.conf"

	info "Configuring $username as trusted user for binary cache access..."

	# Check if user is already trusted
	grep -q "trusted-users.*$username" "$nix_conf" 2>/dev/null && {
		ok "User $username already configured as trusted"
		return
	}

	# Backup the original config
	run_sudo cp "$nix_conf" "$nix_conf.backup.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

	# Add trusted user configuration
	if grep -q "^trusted-users" "$nix_conf" 2>/dev/null; then
		# Update existing trusted-users line to include current user
		local current_trusted
		current_trusted=$(grep "^trusted-users" "$nix_conf" | sed 's/trusted-users = //')
		echo "$current_trusted" | grep -q "$username" ||
			run_sudo sed -i '' "s/^trusted-users = .*/trusted-users = $current_trusted $username/" "$nix_conf"
	else
		echo "trusted-users = root $username" | run_sudo tee -a "$nix_conf" >/dev/null
	fi

	# Also ensure experimental features are enabled for flakes
	if ! grep -q "^experimental-features.*flakes" "$nix_conf" 2>/dev/null; then
		if grep -q "^experimental-features" "$nix_conf" 2>/dev/null; then
			run_sudo sed -i '' 's/^experimental-features = .*/experimental-features = nix-command flakes/' "$nix_conf"
		else
			echo "experimental-features = nix-command flakes" | run_sudo tee -a "$nix_conf" >/dev/null
		fi
	fi

	# Restart nix-daemon to apply changes
	info "Restarting nix-daemon to apply changes..."
	run_sudo launchctl kickstart -k system/org.nixos.nix-daemon 2>/dev/null || true

	# Give daemon a moment to restart
	sleep 2

	ok "User $username configured as trusted user"
}

# --- System Configuration Setup -----------------------------------------------
setup_config() {
	info "Setting up configuration..."

	# Clone or update dotfiles
	if [[ -d $DOTFILES ]]; then
		info "Updating dotfiles..."
		git -C "$DOTFILES" pull --quiet
	else
		info "Cloning dotfiles..."
		git clone "$REPO" "$DOTFILES" --quiet
	fi

	cd "$DOTFILES"

	# Source common functions
	# shellcheck disable=SC1091  # Common functions - sourcing expected here
	source "./lib/common.sh"

	# --- Get Universal System Variables ---
	local username
	username=$(get_username)

	show_system_info

	# Configuration is now fully dynamic - no need to update flake.nix
	info "Using dynamic configuration for user: $username"

	# Backup existing configs
	backup_configs

	# Get configuration name using common function (always 'default' for universality)
	local config_name
	config_name=$(get_config_name)
	info "Using universal configuration: $config_name"

	# Validate flake before building
	info "Validating flake configuration..."
	nix flake check --no-build 2>/dev/null || warn "Flake validation warnings - proceeding"

	# Build and switch configuration
	info "Building configuration: $config_name..."
	if ! nix build ".#darwinConfigurations.$config_name.system" --print-build-logs --show-trace; then
		if [[ $config_name != "default" ]]; then
			warn "Build failed for $config_name, trying default..."
			config_name="default"
			nix build ".#darwinConfigurations.default.system" --print-build-logs --show-trace
		else
			error "Build failed - check configuration"
		fi
	fi

	info "Switching to new configuration..."
	run_sudo ./result/sw/bin/darwin-rebuild switch --flake ".#$config_name"

	ok "Configuration applied successfully"
}

# --- Local Config Backup ------------------------------------------------------
backup_configs() {
	local backup
	backup="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
	local configs=(".zshrc" ".gitconfig" ".config/nix" ".config/op")
	local backed_up=false

	for config in "${configs[@]}"; do
		local path="$HOME/$config"
		[[ -e $path && ! -L $path ]] && {
			[[ -d $backup ]] || mkdir -p "$backup"
			cp -r "$path" "$backup/" && backed_up=true
		}
	done

	[[ $backed_up == true ]] && info "Configurations backed up to: $backup"
}

# --- Post-Installation Tasks --------------------------------------------------
post_install() {
	info "Running post-installation setup..."

	setup_touchid
	setup_1password
	setup_cachix # Optional cache setup
	setup_ssh_keys
	mkdir -p "$HOME"/{.local/bin,bin}
	verify_tools

	ok "Post-installation complete"
}

# --- 1Password CLI Integration ------------------------------------------------
setup_1password() {
	command -v op &>/dev/null || {
		warn "1Password CLI not found, skipping"
		return
	}

	op account list &>/dev/null || {
		warn "1Password CLI not signed in - run: op signin && op plugin init gh"
		return
	}

	info "Setting up 1Password CLI plugins..."
	local plugin="gh"
	if op plugin init "$plugin" &>/dev/null || op plugin list 2>/dev/null | grep -q "^$plugin"; then
		ok "$plugin plugin ready"
	else
		warn "Failed to initialize $plugin plugin"
	fi
}

# --- Secrets-Aware Cachix Setup -----------------------------------------------
setup_cachix() {
	info "Setting up Cachix cache with secrets integration..."

	# Check if secrets are available for automated setup
	if [[ -f "$DOTFILES/secrets/secrets.yaml" ]] && command -v sops &>/dev/null; then
		if sops --decrypt "$DOTFILES/secrets/secrets.yaml" &>/dev/null 2>&1; then
			info "Using automated Cachix setup via encrypted secrets..."
			setup_cachix_automated
			return
		fi
	fi

	# Fall back to manual setup
	warn "Secrets not available - using manual Cachix setup"
	if [[ -x "$DOTFILES/scripts/cachix.sh" ]]; then
		"$DOTFILES/scripts/cachix.sh" setup
	else
		warn "Cachix setup incomplete (configure later)"
	fi
}

setup_cachix_automated() {
	info "Configuring Cachix with automated authentication..."

	# Install cachix if needed
	command -v cachix &>/dev/null || {
		info "Installing cachix..."
		nix-shell -p cachix --run "echo 'Cachix available'" || {
			warn "Failed to install cachix"
			return 1
		}
	}

	# Get token from encrypted secret
	local token
	token=$(sops --decrypt "$DOTFILES/secrets/secrets.yaml" 2>/dev/null | grep "^cachix-auth-token:" | cut -d: -f2- | xargs) || {
		warn "Failed to decrypt cachix token"
		return 1
	}

	# Authenticate cachix
	echo "$token" | nix-shell -p cachix --run "cachix authtoken --stdin" || {
		warn "Failed to authenticate cachix"
		return 1
	}

	# Use the cache (username-based by default)
	local cache_name="${CACHIX_CACHE:-$(whoami)}"
	nix-shell -p cachix --run "cachix use $cache_name" || {
		info "Cache $cache_name not found - you may need to create it first"
	}

	ok "Cachix configured automatically via secrets"
}

# --- SSH Key Setup with 1Password Integration -----------------------------------
setup_ssh_keys() {
	info "Setting up SSH keys with 1Password integration..."

	# Source SSH utilities
	# shellcheck disable=SC1091  # SSH utilities - sourcing expected here
	source "$DOTFILES/lib/ssh.sh" 2>/dev/null || {
		warn "SSH utilities not available - using basic setup"
		setup_ssh_keys_fallback
		return
	}

	# Use the centralized SSH setup script
	if [[ -x "$DOTFILES/scripts/ssh-setup.sh" ]]; then
		"$DOTFILES/scripts/ssh-setup.sh" setup || {
			warn "SSH setup script failed - using fallback"
			setup_ssh_keys_fallback
		}
	else
		warn "SSH setup script not found - using fallback"
		setup_ssh_keys_fallback
	fi
}

# Enhanced SSH key generation with 1Password integration
setup_ssh_keys_fallback() {
	info "Setting up SSH key..."

	# Check if SSH key already exists
	if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
		ok "SSH key already exists"
		offer_1password_import
		return
	fi

	# Offer 1Password SSH key generation if available
	if command -v op &>/dev/null && op account get &>/dev/null 2>&1; then
		echo ""
		echo "SSH Key Options:"
		echo "1. Generate new SSH key in 1Password (recommended)"
		echo "2. Generate traditional SSH key file"
		echo ""
		read -rp "Choose option (1-2, default 1): " ssh_choice

		case "${ssh_choice:-1}" in
		1)
			generate_1password_ssh_key
			return
			;;
		2)
			generate_traditional_ssh_key
			;;
		*)
			warn "Invalid choice, using traditional SSH key"
			generate_traditional_ssh_key
			;;
		esac
	else
		generate_traditional_ssh_key
	fi
}

generate_1password_ssh_key() {
	info "Generating SSH key in 1Password..."

	# Source 1Password helpers
	# shellcheck disable=SC1091  # 1Password helpers - sourcing expected here
	source "$DOTFILES/lib/1password.sh" 2>/dev/null || {
		warn "1Password helpers not available, falling back to traditional key"
		generate_traditional_ssh_key
		return
	}

	# Prompt for key name
	local key_name
	read -rp "Enter SSH key name (default: dev-key): " key_name
	key_name="${key_name:-dev-key}"

	# Generate SSH key in 1Password
	if op_generate_ssh_key "$key_name" "Private"; then
		ok "SSH key '$key_name' generated in 1Password!"
		echo ""
		echo "Next steps:"
		echo "1. SSH agent is already configured in your dotfiles"
		echo "2. Add the public key to your Git providers:"
		echo ""

		# Try to show public key
		local pub_key
		if pub_key=$(op_get_ssh_public_key "SSH Key - $key_name" "Private" 2>/dev/null); then
			echo "$pub_key"
		else
			echo "   Get public key from 1Password app or run:"
			echo "   op item get 'SSH Key - $key_name' --fields='public key'"
		fi
		echo ""
	else
		warn "Failed to generate SSH key in 1Password, falling back to traditional key"
		generate_traditional_ssh_key
	fi
}

generate_traditional_ssh_key() {
	read -rp "Enter email for SSH key (or press Enter to skip): " email
	[[ -z $email ]] && {
		info "SSH key setup skipped"
		return
	}

	info "Generating traditional SSH key..."
	mkdir -p "$HOME/.ssh"
	chmod 700 "$HOME/.ssh"

	ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N "" -q
	ok "SSH key generated. Add to your Git provider:"
	cat "$HOME/.ssh/id_ed25519.pub"
	echo

	offer_1password_import
}

offer_1password_import() {
	if command -v op &>/dev/null && op account get &>/dev/null 2>&1; then
		echo ""
		echo "🔐 1Password Integration:"
		echo "Your SSH key exists but could be better managed with 1Password."
		echo ""
		read -rp "Import SSH key to 1Password now? (y/N): " import_choice

		if [[ $import_choice =~ ^[Yy]$ ]]; then
			warn "Automatic SSH key import is not supported by 1Password CLI"
			echo ""
			echo "Manual import steps:"
			echo "1. Open 1Password app"
			echo "2. Create new item → SSH Key"
			echo "3. Import your key from ~/.ssh/id_ed25519"
			echo "4. Enable SSH agent in 1Password settings"
			echo ""
			echo "Alternative: Delete ~/.ssh/id_ed25519* and re-run bootstrap to generate in 1Password"
		else
			echo ""
			echo "Consider setting up 1Password SSH agent for better key management:"
			echo "1. Enable SSH agent in 1Password settings"
			echo "2. Import your SSH key into 1Password"
			echo "3. Your dotfiles already configure the SSH agent"
		fi
	else
		warn "Consider setting up 1Password SSH agent for better key management:"
		warn "1. Install 1Password CLI and sign in"
		warn "2. Enable SSH agent in 1Password settings"
		warn "3. Import your SSH key into 1Password"
	fi
}

# --- Touch ID for Sudo --------------------------------------------------------
setup_touchid() {
	info "Enabling Touch ID for sudo..."
	local pam_file="/etc/pam.d/sudo"

	grep -q "pam_tid.so" "$pam_file" 2>/dev/null && {
		ok "Touch ID already enabled for sudo"
		return
	}

	run_sudo cp "$pam_file" "$pam_file.backup"

	# Add Touch ID support (insert after first line)
	run_sudo sed -i '' '1a\
auth       sufficient     pam_tid.so
' "$pam_file" 2>/dev/null || warn "Could not enable Touch ID for sudo"

	ok "Touch ID enabled for sudo"
}

# --- Tool Verification --------------------------------------------------------
verify_tools() {
	info "Verifying installation..."
	local tools=(nix:Nix darwin-rebuild:nix-darwin op:1Password gh:GitHub)

	for tool in "${tools[@]}"; do
		local cmd="${tool%%:*}" desc="${tool##*:}"
		if command -v "$cmd" &>/dev/null; then
			ok "$desc: ✓"
		else
			warn "$desc: ✗ (restart terminal if needed)"
		fi
	done
}

# --- Finalization -------------------------------------------------------------
finalize() {
	info "Finalizing setup..."

	# Source updated shell configuration if available
	if [[ -f "$HOME/.zshrc" ]]; then
		# shellcheck disable=SC1091  # User's zshrc - sourcing expected here
		source "$HOME/.zshrc" 2>/dev/null || true
	fi

	ok "Bootstrap complete!"
	echo
	echo "Next steps:"
	echo "  • Restart terminal: exec zsh"
	echo "  • Sign into 1Password: op signin && op plugin init gh"
	echo "  • Enable 1Password SSH agent in settings for automatic SSH key access"
	echo "  • Review config: $DOTFILES"

	# Check if secrets are set up
	if [[ -f "$DOTFILES/secrets/secrets.yaml" ]]; then
		echo
		echo "✅ Secrets Management:"
		echo "  • Automated authentication: ENABLED"
		echo "  • Cache access: AUTOMATED"
		echo "  • Future rebuilds: ZERO manual intervention"
	else
		echo
		echo "🔐 Secrets Management (Optional but Recommended):"
		echo "  • For full automation: $DOTFILES/scripts/setup-1password.sh"
		echo "  • Enables automated cache access and API integration"
		echo "  • One-time setup with 1Password integration"
	fi

	echo
	echo "Useful commands:"
	echo "  • Rebuild: $DOTFILES/scripts/rebuild.sh"
	echo "  • Update: cd $DOTFILES && nix flake update && ./scripts/rebuild.sh"
	echo "  • Setup cache: $DOTFILES/scripts/cachix.sh setup"
	echo "  • Setup secrets: $DOTFILES/scripts/setup-1password.sh"
	echo "  • SSH setup: $DOTFILES/scripts/ssh-setup.sh setup"
	echo "  • SSH health: $DOTFILES/scripts/ssh-setup.sh health"
}

# --- Main Execution -----------------------------------------------------------
main() {
	echo "macOS Bootstrap: nix-darwin + home-manager"
	echo "=============================================="
	echo

	check_prereqs
	# Homebrew now managed by nix-homebrew during darwin-rebuild
	install_nix
	setup_config
	post_install
	finalize
}

# Run if executed directly (not sourced)
[[ ${BASH_SOURCE[0]} == "${0}" ]] && main "$@"
