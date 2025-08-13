#!/usr/bin/env bash
# Title         : common.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : lib/common.sh
# ---------------------------------------
# Universal system detection and semantic variables for cross-platform consistency

# --- XDG Base Directory Specification ----------------------------------------
# Export XDG variables for script usage (with fallbacks)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Get XDG directory with guaranteed value
# XDG paths resolve to:
#   config:  ~/.config          (application configuration)
#   data:    ~/.local/share     (application data)
#   cache:   ~/.cache           (non-essential cached data)
#   state:   ~/.local/state     (application state data)
#   backups: ~/.local/share/backups (our custom backup location)
get_xdg_dir() {
    case "$1" in
    config) echo "$XDG_CONFIG_HOME" ;;
    data) echo "$XDG_DATA_HOME" ;;
    cache) echo "$XDG_CACHE_HOME" ;;
    state) echo "$XDG_STATE_HOME" ;;
    backups) echo "$XDG_DATA_HOME/backups" ;; # Standard backup location
    *) echo "$HOME" ;;
    esac
}

# --- Semantic Variable Functions -------------------------------------------------

# Get current username - universal across all contexts
get_username() {
    whoami
}

# Get system hostname - normalized and universal
# For config naming, we use "default" to ensure universal compatibility
get_system_host() {
    echo "default"
}

# Get system architecture in Nix format
get_system_arch() {
    case "$(uname -m)" in
    "arm64") echo "aarch64-darwin" ;;
    "x86_64") echo "x86_64-darwin" ;;
    *) echo "$(uname -m)-darwin" ;;
    esac
}

# --- Configuration Helper Functions ----------------------------------------------

# Check if a Darwin configuration exists
# Always check for "default" since we use universal config
config_exists() {
    local config_name="${1:-default}"
    if command -v jq &>/dev/null; then
        nix flake show --json 2>/dev/null | jq -e ".darwinConfigurations.\"${config_name}\"" &>/dev/null
    else
        nix flake show --json 2>/dev/null | grep -q "\"${config_name}\""
    fi
}

# Get the configuration name to use - always "default" for universal approach
get_config_name() {
    echo "default"
}

# --- Standard Error Handling Functions -------------------------------------------

# Standard error handler for all scripts
handle_error() {
    local message="${1:-Unknown error occurred}"
    local exit_code="${2:-1}"
    echo "Error: $message" >&2
    exit "$exit_code"
}

# Check if required command exists
require_command() {
    local cmd="$1"
    local friendly_name="${2:-$cmd}"
    if ! command -v "$cmd" &>/dev/null; then
        handle_error "Required command '$friendly_name' not found. Please install it first." 127
    fi
}

# Verify file exists
require_file() {
    local file="$1"
    if [[ ! -f $file ]]; then
        handle_error "Required file '$file' not found" 2
    fi
}

# Verify directory exists
require_dir() {
    local dir="$1"
    if [[ ! -d $dir ]]; then
        handle_error "Required directory '$dir' not found" 2
    fi
}

# Safe command execution with error handling
safe_execute() {
    local cmd="$1"
    local error_msg="${2:-Command failed: $cmd}"
    if ! eval "$cmd"; then
        handle_error "$error_msg" $?
    fi
}

# --- System Information Display --------------------------------------------------

# Display current system information
show_system_info() {
    echo "=========================="
    echo "Username: $(get_username)"
    echo "System Host: $(get_system_host)"
    echo "System Arch: $(get_system_arch)"
    echo "Config Name: $(get_config_name)"
    echo "=========================="
}

# --- File Operation Helpers ------------------------------------------------------

# Safe move with confirmation for overwrites
safe_move() {
    local source="$1"
    local dest="$2"

    if [[ ! -e $source ]]; then
        handle_error "Source file '$source' does not exist" 2
    fi

    if [[ -e $dest ]]; then
        echo "Warning: Destination '$dest' already exists."
        read -p "Overwrite? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Move cancelled."
            return 1
        fi
    fi

    mv "$source" "$dest"
}

# Create timestamped backup of a file
ensure_backup() {
    local file="$1"
    local backup_dir="${2:-$(get_xdg_dir backups)}"

    if [[ ! -f $file ]]; then
        handle_error "File '$file' does not exist" 2
    fi

    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"

    # Generate timestamp
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local filename
    filename=$(basename "$file")
    local backup_path="$backup_dir/${filename}.${timestamp}.bak"

    # Create backup
    cp "$file" "$backup_path"
    echo "Backup created: $backup_path"
}

# Use fd if available, fallback to find
fd_or_find() {
    local pattern="$1"
    shift

    if command -v fd &>/dev/null; then
        fd "$pattern" "$@"
    else
        # Translate to find syntax
        find . -name "*${pattern}*" "$@"
    fi
}

# Check if path is safe to delete (not system critical)
is_safe_to_delete() {
    local path="$1"

    # Define protected paths
    local protected_paths=(
        "/"
        "/bin"
        "/sbin"
        "/usr"
        "/etc"
        "/System"
        "/Library"
        "/Applications"
        "$HOME/Library"
        "$HOME/Applications"
    )

    # Get absolute path
    local abs_path
    abs_path=$(cd "$(dirname "$path")" 2>/dev/null && pwd)/$(basename "$path")

    # Check against protected paths
    for protected in "${protected_paths[@]}"; do
        if [[ $abs_path == "$protected" ]] || [[ $abs_path == "$protected/"* ]]; then
            return 1 # Not safe
        fi
    done

    return 0 # Safe
}

# Get human-readable file size
get_file_size() {
    local file="$1"

    if [[ ! -e $file ]]; then
        echo "0B"
        return
    fi

    # Try different methods for compatibility
    if command -v stat &>/dev/null; then
        # macOS
        stat -f%z "$file" 2>/dev/null | awk '{
      if ($1 >= 1073741824) printf "%.1fG\n", $1/1073741824
      else if ($1 >= 1048576) printf "%.1fM\n", $1/1048576  
      else if ($1 >= 1024) printf "%.1fK\n", $1/1024
      else printf "%dB\n", $1
    }' ||
            # Linux
            stat -c%s "$file" 2>/dev/null | awk '{
      if ($1 >= 1073741824) printf "%.1fG\n", $1/1073741824
      else if ($1 >= 1048576) printf "%.1fM\n", $1/1048576
      else if ($1 >= 1024) printf "%.1fK\n", $1/1024
      else printf "%dB\n", $1
    }'
    else
        du -h "$file" 2>/dev/null | cut -f1
    fi
}

# --- Generation Management Functions ---------------------------------------------

# Get current system generation number
get_current_generation() {
    if [[ -L /nix/var/nix/profiles/system ]]; then
        readlink /nix/var/nix/profiles/system | sed 's/.*system-\([0-9]*\)-link/\1/'
    else
        echo "0"
    fi
}

# List all system generations
list_generations() {
    if command -v darwin-rebuild &>/dev/null; then
        darwin-rebuild --list-generations 2>/dev/null
    elif [[ -d /nix/var/nix/profiles ]]; then
        find /nix/var/nix/profiles -maxdepth 1 -name "system-*-link" -type l 2>/dev/null |
            sed 's/.*system-\([0-9]*\)-link.*/Generation \1/' | sort -V
    else
        echo "No generations found"
    fi
}

# Compare two generation closures
generation_diff() {
    local gen1="${1:-$(($(get_current_generation) - 1))}"
    local gen2="${2:-$(get_current_generation)}"

    local path1="/nix/var/nix/profiles/system-${gen1}-link"
    local path2="/nix/var/nix/profiles/system-${gen2}-link"

    if [[ ! -e $path1 ]]; then
        echo "Generation $gen1 not found"
        return 1
    fi

    if [[ ! -e $path2 ]]; then
        echo "Generation $gen2 not found"
        return 1
    fi

    echo "Comparing generation $gen1 with $gen2:"

    # Use nvd if available for prettier output
    if command -v nvd &>/dev/null; then
        nvd diff "$path1" "$path2"
    else
        nix store diff-closures "$path1" "$path2"
    fi
}

# Get home-manager generation (if using home-manager)
get_home_generation() {
    local profile="$HOME/.local/state/nix/profiles/home-manager"
    if [[ -L $profile ]]; then
        readlink "$profile" | sed 's/.*home-manager-\([0-9]*\)-link/\1/'
    else
        echo "0"
    fi
}
