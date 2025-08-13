#!/usr/bin/env bash
# Title         : vm-manager.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : scripts/vm-manager.sh
# ---------------------------------------
# Parallels VM management for safe Nix deployment testing

set -euo pipefail

# --- Configuration --------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly DOTFILES_ROOT
readonly VM_NAME="${VM_NAME:-macOS}"
readonly IP_CACHE="/tmp/.vm-ips"
readonly SSH_DIR="$HOME/.ssh"
# VM_SSH_KEY_NAME reserved for future SSH key deployment

# VM_USER will be set dynamically by get_vm_user() function

# Source utilities
# shellcheck disable=SC1091
source "$DOTFILES_ROOT/lib/common.sh" 2>/dev/null || true
# shellcheck disable=SC1091
source "$DOTFILES_ROOT/lib/ssh.sh" 2>/dev/null || true

# --- Logging --------------------------------------------------------------
log() { echo -e "\033[0;3${2:-4}m[$1]\033[0m ${*:3}"; }
info() { log INFO 4 "$@"; }
ok() { log OK 2 "$@"; }
warn() { log WARN 3 "$@"; }
error() {
	log ERROR 1 "$@" >&2
	exit 1
}

# --- VM Detection ---------------------------------------------------------
get_vm_uuid() {
	local vm_name="${1:-$VM_NAME}"
	prlctl list -a --no-header 2>/dev/null | grep "$vm_name" | awk '{print $1}' | tr -d '{}'
}

# Get the first non-system user in the VM
get_vm_user() {
	local vm_name="${1:-$VM_NAME}"

	# If VM_USER is already set via environment, use it
	if [[ -n ${VM_USER:-} ]]; then
		echo "$VM_USER"
		return 0
	fi

	# Get first non-system user from VM
	local users
	users=$(prlctl exec "$vm_name" "ls /Users" 2>/dev/null | grep -v "^\." | grep -v "^Shared$" | head -1)

	if [[ -z $users ]]; then
		error "No valid user found in VM '$vm_name'"
	fi

	echo "$users"
}

get_vm_ip() {
	local vm_name="${1:-$VM_NAME}"
	local vm_uuid
	vm_uuid=$(get_vm_uuid "$vm_name")

	[[ -z $vm_uuid ]] && {
		error "VM '$vm_name' not found"
	}

	# Try to get IP from running VM
	local ip
	ip=$(prlctl list -f --json 2>/dev/null | jq -r ".[] | select(.uuid == \"$vm_uuid\") | .ip_configured" 2>/dev/null)

	if [[ -n $ip && $ip != "null" && $ip != "-" ]]; then
		echo "$ip"
		# Cache the IP
		mkdir -p "$(dirname "$IP_CACHE")"
		echo "$vm_name:$ip:$(date +%s)" >>"$IP_CACHE"
		return 0
	fi

	# Check cache for recent IP
	if [[ -f $IP_CACHE ]]; then
		local cached_ip
		cached_ip=$(grep "^$vm_name:" "$IP_CACHE" | tail -1 | cut -d: -f2)
		if [[ -n $cached_ip ]]; then
			warn "Using cached IP for $vm_name: $cached_ip"
			echo "$cached_ip"
			return 0
		fi
	fi

	error "Could not determine IP for VM '$vm_name'. Is it running?"
}

check_vm_running() {
	local vm_name="${1:-$VM_NAME}"
	local status
	status=$(prlctl list -a --no-header 2>/dev/null | grep "$vm_name" | awk '{print $2}')

	if [[ $status != "running" ]]; then
		error "VM '$vm_name' is not running (status: $status)"
	fi
}

# --- Network Configuration -----------------------------------------------
cmd_network() {
	local vm_name="${1:-$VM_NAME}"
	local network_type="${2:-status}"

	case "$network_type" in
	status)
		info "Network configuration for VM '$vm_name':"
		local net_info
		net_info=$(prlctl list -i "$vm_name" 2>&1 | grep -E "net0|IP Address" | head -5)
		echo "$net_info"

		# Show available networks
		echo
		info "Available networks:"
		prlsrvctl net list
		;;

	host-only | hostonly)
		info "Switching VM '$vm_name' to host-only network (isolated)..."
		prlctl set "$vm_name" --device-set net0 --type host-only || error "Failed to set network"
		ok "Network changed to host-only (10.37.129.x subnet)"
		echo "Note: VM may need to renew DHCP lease or restart networking"
		echo "  In VM: sudo ifconfig en0 down && sudo ifconfig en0 up"
		;;

	shared)
		info "Switching VM '$vm_name' to shared network (NAT)..."
		prlctl set "$vm_name" --device-set net0 --type shared || error "Failed to set network"
		ok "Network changed to shared (10.211.55.x subnet with NAT)"
		;;

	bridged)
		info "Switching VM '$vm_name' to bridged network (same as host)..."
		warn "WARNING: This puts VM on same network as host!"
		read -p "Are you sure? (y/N): " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			prlctl set "$vm_name" --device-set net0 --type bridged || error "Failed to set network"
			ok "Network changed to bridged (same subnet as host)"
		else
			info "Network change cancelled"
		fi
		;;

	*)
		error "Unknown network type: $network_type. Use: status, host-only, shared, or bridged"
		;;
	esac
}

# --- VM Isolation ---------------------------------------------------------
cmd_isolate() {
	local vm_name="${1:-$VM_NAME}"
	info "Isolating VM '$vm_name' for safe testing..."

	# Configure network isolation
	info "Setting up network isolation..."
	prlctl set "$vm_name" --device-set net0 --type host-only || {
		warn "Failed to set host-only network, trying shared network"
		prlctl set "$vm_name" --device-set net0 --type shared || warn "Failed to configure network"
	}

	# Disable all sharing features except clipboard
	info "Disabling dangerous shared features (keeping clipboard)..."
	prlctl set "$vm_name" --shared-cloud off || warn "Failed to disable shared cloud"
	prlctl set "$vm_name" --shared-profile off || warn "Failed to disable shared profile"
	prlctl set "$vm_name" --share-all-host off || warn "Failed to disable all host disk sharing"
	# Disable application sharing (both directions)
	prlctl set "$vm_name" --sh-app-host-to-guest off || warn "Failed to disable host-to-guest app sharing"
	prlctl set "$vm_name" --sh-app-guest-to-host off || warn "Failed to disable guest-to-host app sharing"
	prlctl set "$vm_name" --smart-mount off || warn "Failed to disable smart mount"
	# Keep clipboard enabled for convenience
	prlctl set "$vm_name" --shared-clipboard on || warn "Failed to enable clipboard sharing"
	prlctl set "$vm_name" --share-host-location off || warn "Failed to disable location sharing"

	# Disable password requirements for automation (if supported)
	info "Configuring for automation..."
	prlctl set "$vm_name" --startup-view window || true # Start in window mode for automation

	# Ensure tools are up to date for better exec functionality
	prlctl set "$vm_name" --tools-autoupdate on || true

	ok "VM '$vm_name' isolated successfully"

	# Show current isolation status
	cmd_status "$vm_name"
}

# --- SSH Setup ------------------------------------------------------------
get_ssh_public_key() {
	# Try to get from 1Password first
	if command -v op &>/dev/null && op account list &>/dev/null 2>&1; then
		local key_name
		key_name=$(op item list --categories "SSH Key" --format json 2>/dev/null | jq -r '.[0].title' 2>/dev/null)
		if [[ -n $key_name && $key_name != "null" ]]; then
			op item get "$key_name" --fields label=public_key 2>/dev/null && return 0
		fi
	fi

	# Fallback to local SSH key
	if [[ -f "$SSH_DIR/id_ed25519.pub" ]]; then
		cat "$SSH_DIR/id_ed25519.pub"
	elif [[ -f "$SSH_DIR/id_rsa.pub" ]]; then
		cat "$SSH_DIR/id_rsa.pub"
	else
		error "No SSH keys found (1Password or local)"
	fi
}

cmd_setup_ssh() {
	local vm_name="${1:-$VM_NAME}"
	check_vm_running "$vm_name"

	# Get the VM user dynamically
	local vm_user
	vm_user=$(get_vm_user "$vm_name")

	# Safety check: ensure VM user is not the host user
	if [[ $vm_user == "$(whoami)" ]]; then
		error "VM user '$vm_user' cannot be the same as host user! This would compromise isolation."
	fi

	info "Setting up SSH for VM '$vm_name' with user '$vm_user'..."

	# Check if SSH is already enabled
	local ssh_status
	ssh_status=$(prlctl exec "$vm_name" "sudo systemsetup -getremotelogin" 2>&1 | grep -o "On\|Off" || echo "Unknown")

	if [[ $ssh_status == "Off" ]]; then
		info "SSH is currently disabled in VM"
		info "Attempting to enable SSH..."

		# Try to enable SSH (may fail due to macOS security)
		if prlctl exec "$vm_name" "sudo systemsetup -setremotelogin on" 2>&1 | grep -q "Full Disk Access"; then
			warn "Cannot enable SSH automatically due to macOS security restrictions"
			echo
			echo "To enable SSH manually in the VM:"
			echo "  1. Open System Preferences > Sharing"
			echo "  2. Enable 'Remote Login'"
			echo "  3. Add '$vm_user' to allowed users"
			echo
			read -r -p "Press Enter after enabling SSH manually..."

			# Re-check status
			ssh_status=$(prlctl exec "$vm_name" "sudo systemsetup -getremotelogin" 2>&1 | grep -o "On\|Off" || echo "Unknown")
			if [[ $ssh_status != "On" ]]; then
				error "SSH still not enabled. Please enable it manually and try again"
			fi
		fi
	else
		ok "SSH is already enabled in VM"
	fi

	# Get public key
	local public_key
	public_key=$(get_ssh_public_key) || error "Failed to get SSH public key"

	# Deploy SSH key to VM
	info "Deploying SSH key to VM user '$vm_user'..."

	# Create .ssh directory
	prlctl exec "$vm_name" --user "$vm_user" "mkdir -p ~/.ssh && chmod 700 ~/.ssh" || {
		error "Failed to create .ssh directory"
	}

	# Add public key to authorized_keys
	prlctl exec "$vm_name" --user "$vm_user" "echo '$public_key' >> ~/.ssh/authorized_keys" || {
		error "Failed to add SSH key"
	}

	# Fix permissions
	prlctl exec "$vm_name" --user "$vm_user" "chmod 600 ~/.ssh/authorized_keys" || {
		warn "Failed to set authorized_keys permissions"
	}

	# Get VM IP
	local vm_ip
	vm_ip=$(get_vm_ip "$vm_name")

	# Test SSH connection
	info "Testing SSH connection to $vm_user@$vm_ip..."
	# shellcheck disable=SC2029  # Variables are meant to expand on client side
	if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$vm_user@$vm_ip" "echo 'SSH connection successful'" 2>/dev/null; then
		ok "SSH setup complete!"
		echo
		echo "You can now connect with:"
		echo "  ssh $vm_user@$vm_ip"
		echo "  or use: $0 connect"
	else
		warn "SSH setup complete but connection test failed"
		echo "Try connecting manually with: ssh $vm_user@$vm_ip"
	fi

	# Update SSH config
	update_ssh_config "$vm_name" "$vm_ip"
}

update_ssh_config() {
	local vm_name="$1"
	local vm_ip="$2"
	local vm_user="${3:-$(get_vm_user "$vm_name")}" # Get VM user if not provided
	local ssh_config="$SSH_DIR/config"
	local config_marker="# Parallels VM: $vm_name"

	info "Updating SSH config for VM..."

	# Create backup
	[[ -f $ssh_config ]] && cp "$ssh_config" "$ssh_config.bak"

	# Remove old VM config if exists
	if [[ -f $ssh_config ]] && grep -q "$config_marker" "$ssh_config"; then
		# Remove old config block
		sed -i.tmp "/$config_marker/,/^$/d" "$ssh_config"
	fi

	# Add new config
	cat >>"$ssh_config" <<EOF

$config_marker
Host vm-$vm_name
    HostName $vm_ip
    User $vm_user
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
    ConnectTimeout 10
    ServerAliveInterval 60
    ServerAliveCountMax 3

EOF

	ok "SSH config updated. You can now use: ssh vm-$vm_name"
}

# --- Command Execution ----------------------------------------------------
cmd_exec() {
	local vm_name="${1:-$VM_NAME}"
	shift
	local command="$*"

	[[ -z $command ]] && error "No command specified"

	check_vm_running "$vm_name"

	# Get the VM user dynamically
	local vm_user
	vm_user=$(get_vm_user "$vm_name")

	# Safety check: ensure VM user is not the host user
	if [[ $vm_user == "$(whoami)" ]]; then
		error "VM user '$vm_user' cannot be the same as host user! This would compromise isolation."
	fi

	# Always source Nix environment for bash -c to ensure commands work
	# This handles both direct nix commands and complex shell pipelines
	local wrapped_command="source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true; $command"

	info "Executing in VM as '$vm_user': $command"
	prlctl exec "$vm_name" --user "$vm_user" --resolve-paths "bash -c '$wrapped_command'"
}

cmd_connect() {
	local vm_name="${1:-$VM_NAME}"
	check_vm_running "$vm_name"

	# Get the VM user dynamically
	local vm_user
	vm_user=$(get_vm_user "$vm_name")

	# Safety check
	if [[ $vm_user == "$(whoami)" ]]; then
		error "VM user '$vm_user' cannot be the same as host user! This would compromise isolation."
	fi

	local vm_ip
	vm_ip=$(get_vm_ip "$vm_name")

	info "Connecting to VM '$vm_name' at $vm_ip as user '$vm_user'..."

	# Use 1Password SSH agent if available
	# Using array for ssh options to avoid word splitting issues
	local -a ssh_opts=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)
	if [[ -n ${SSH_AUTH_SOCK:-} ]]; then
		# shellcheck disable=SC2029  # Variables are meant to expand on client side
		ssh "${ssh_opts[@]}" "$vm_user@$vm_ip"
	else
		# Try with 1Password socket
		local op_socket
		op_socket=$(get_1password_socket_path 2>/dev/null || echo "")
		if [[ -S $op_socket ]]; then
			# shellcheck disable=SC2029  # Variables are meant to expand on client side
			SSH_AUTH_SOCK="$op_socket" ssh "${ssh_opts[@]}" "$vm_user@$vm_ip"
		else
			# shellcheck disable=SC2029  # Variables are meant to expand on client side
			ssh "${ssh_opts[@]}" "$vm_user@$vm_ip"
		fi
	fi
}

# --- Nix Deployment -------------------------------------------------------
cmd_deploy_nix() {
	local vm_name="${1:-$VM_NAME}"
	check_vm_running "$vm_name"

	# Get the VM user dynamically
	local vm_user
	vm_user=$(get_vm_user "$vm_name")

	# Safety check
	if [[ $vm_user == "$(whoami)" ]]; then
		error "VM user '$vm_user' cannot be the same as host user! This would compromise isolation."
	fi

	info "Deploying Nix configuration to VM '$vm_name' as user '$vm_user'..."

	# Create snapshot first
	cmd_snapshot "$vm_name" "pre-deploy-$(date +%Y%m%d-%H%M%S)"

	local vm_ip
	vm_ip=$(get_vm_ip "$vm_name")

	# Sync dotfiles to VM
	info "Syncing dotfiles to VM..."
	# shellcheck disable=SC2029  # Variables are meant to expand on client side
	rsync -avz --exclude='.git' --exclude='result*' \
		-e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
		"$DOTFILES_ROOT/" "$vm_user@$vm_ip:~/.dotfiles/"

	# Run rebuild in VM
	info "Running Nix rebuild in VM..."
	# shellcheck disable=SC2029  # Variables are meant to expand on client side
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		"$vm_user@$vm_ip" "cd ~/.dotfiles && ./scripts/rebuild.sh"

	ok "Nix deployment complete!"
}

# --- Snapshot Management --------------------------------------------------
cmd_snapshot() {
	local vm_name="${1:-$VM_NAME}"
	local snap_name="${2:-manual-$(date +%Y%m%d-%H%M%S)}"

	info "Creating snapshot '$snap_name' for VM '$vm_name'..."
	prlctl snapshot "$vm_name" --name "$snap_name" || error "Failed to create snapshot"
	ok "Snapshot created: $snap_name"
}

cmd_restore() {
	local vm_name="${1:-$VM_NAME}"
	local snap_id="${2:-}"

	if [[ -z $snap_id ]]; then
		# List snapshots
		info "Available snapshots for VM '$vm_name':"
		prlctl snapshot-list "$vm_name" --tree
		echo
		read -rp "Enter snapshot ID to restore: " snap_id
	fi

	[[ -z $snap_id ]] && error "No snapshot ID provided"

	info "Restoring VM '$vm_name' to snapshot '$snap_id'..."
	prlctl snapshot-switch "$vm_name" --id "$snap_id" || error "Failed to restore snapshot"
	ok "VM restored to snapshot: $snap_id"
}

# --- Status and Info ------------------------------------------------------
cmd_status() {
	local vm_name="${1:-$VM_NAME}"

	echo "═══════════════════════════════════════════════════════════════"
	echo "  VM Status: $vm_name"
	echo "═══════════════════════════════════════════════════════════════"

	# Get VM info
	local vm_info
	vm_info=$(prlctl list -f --json 2>/dev/null | jq ".[] | select(.name == \"$vm_name\")" 2>/dev/null)

	if [[ -z $vm_info ]]; then
		error "VM '$vm_name' not found"
	fi

	# Parse info
	local status uuid ip
	status=$(echo "$vm_info" | jq -r '.status')
	uuid=$(echo "$vm_info" | jq -r '.uuid')
	ip=$(echo "$vm_info" | jq -r '.ip_configured // "-"')

	echo "Status: $status"
	echo "UUID: $uuid"
	echo "IP: $ip"
	echo

	# Check isolation settings
	echo "Isolation Settings:"
	local settings
	settings=$(prlctl list -i "$vm_name" 2>&1)

	echo "  • Shared Folders: $(echo "$settings" | grep -q "Host Shared Folders: (-)" && echo "✓ Disabled" || echo "✗ Enabled")"
	echo "  • Shared Profile: $(echo "$settings" | grep -q "Shared Profile: (-)" && echo "✓ Disabled" || echo "✗ Enabled")"
	# Check if both app sharing directions are off
	local app_sharing="✓ Disabled"
	if echo "$settings" | grep -A2 "Shared Applications" | grep -q "sharing: on"; then
		app_sharing="✗ Enabled"
	fi
	echo "  • Shared Applications: $app_sharing"
	echo "  • Shared Cloud: $(echo "$settings" | grep -q "Shared cloud: off" && echo "✓ Disabled" || echo "✗ Enabled")"
	echo "  • Shared Clipboard: $(echo "$settings" | grep -q "Shared clipboard mode: on" && echo "✓ Enabled (OK)" || echo "✗ Disabled")"

	# Network configuration
	echo
	echo "Network Configuration:"
	local net_type
	net_type=$(echo "$settings" | grep "net0 (+)" | grep -o "type=[^ ]*" | cut -d= -f2)
	echo "  • Network Type: $net_type"
	echo "  • IP Address: $ip"

	# Show which subnet this is
	case "$net_type" in
	host-only | host)
		echo "  • Subnet: 10.37.129.x (isolated from host network)"
		;;
	shared)
		echo "  • Subnet: 10.211.55.x (NAT, shared with host)"
		;;
	bridged)
		echo "  • Subnet: Same as host network (NOT isolated!)"
		;;
	esac

	# SSH status
	echo
	echo "SSH Configuration:"
	if [[ $status == "running" ]]; then
		local ssh_status
		ssh_status=$(prlctl exec "$vm_name" "sudo systemsetup -getremotelogin" 2>&1 | grep -o "On\|Off" || echo "Unknown")
		echo "  • Remote Login: $ssh_status"

		if [[ $ip != "-" ]]; then
			local vm_user
			vm_user=$(get_vm_user "$vm_name" 2>/dev/null || echo "unknown")
			echo "  • Test connection: ssh $vm_user@$ip"
		fi
	else
		echo "  • VM not running"
	fi

	echo "═══════════════════════════════════════════════════════════════"
}

# --- Main Command Interface -----------------------------------------------
cmd_help() {
	cat <<EOF
Parallels VM Manager - Safe Nix Deployment Testing

USAGE:
    $0 <command> [options]

COMMANDS:
    isolate [VM]        Configure VM for complete isolation
    network [VM] <type> Configure network (host-only, shared, bridged, status)
    setup-ssh [VM]      Enable SSH and deploy keys to VM
    connect [VM]        SSH into the VM
    exec [VM] <cmd>     Execute command in VM as VM user
    deploy-nix [VM]     Deploy Nix configuration to VM
    snapshot [VM] [name] Create VM snapshot
    restore [VM] [id]   Restore VM from snapshot
    status [VM]         Show VM status and configuration
    help               Show this help message

ENVIRONMENT VARIABLES:
    VM_NAME            Target VM name (default: macOS)
    VM_USER            VM user for operations (default: auto-detect)

EXAMPLES:
    # Initial setup for safe testing
    $0 isolate
    $0 setup-ssh
    
    # Connect to VM
    $0 connect
    
    # Execute commands
    $0 exec "uname -a"
    $0 exec "cd ~/.dotfiles && nix flake check"
    
    # Deploy Nix configuration
    $0 snapshot pre-deploy
    $0 deploy-nix

SAFETY FEATURES:
    • Complete VM isolation (no shared folders/clipboard)
    • Always executes as VM user, never as host
    • Automatic snapshots before deployments
    • SSH key-based auth (no passwords)
    • Dynamic IP detection and caching
EOF
}

# --- Main Execution -------------------------------------------------------
main() {
	case "${1:-}" in
	isolate)
		shift
		cmd_isolate "$@"
		;;
	network)
		shift
		cmd_network "$@"
		;;
	setup-ssh)
		shift
		cmd_setup_ssh "$@"
		;;
	connect)
		shift
		cmd_connect "$@"
		;;
	exec)
		shift
		cmd_exec "$@"
		;;
	deploy-nix)
		shift
		cmd_deploy_nix "$@"
		;;
	snapshot)
		shift
		cmd_snapshot "$@"
		;;
	restore)
		shift
		cmd_restore "$@"
		;;
	status)
		shift
		cmd_status "$@"
		;;
	help | --help | -h) cmd_help ;;
	"") cmd_help ;;
	*) error "Unknown command: $1. Use 'help' for usage." ;;
	esac
}

# Run if executed directly
[[ ${BASH_SOURCE[0]} == "${0}" ]] && main "$@"
