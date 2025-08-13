#!/usr/bin/env bash
# Title         : extract.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : bin/extract.sh
# ---------------------------------------
# Universal archive extraction utility with format detection and validation

set -euo pipefail

# Source common functions if available
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
# shellcheck source=/dev/null
[[ -f "${DOTFILES}/lib/common.sh" ]] && source "${DOTFILES}/lib/common.sh"

# Display usage information
show_usage() {
    cat <<'EOF'
extract - Universal Archive Extraction Utility

USAGE:
    extract <file> [destination]
    extract --list <file>
    extract --help

OPTIONS:
    --list, -l     List archive contents without extracting
    --help, -h     Show this help message

SUPPORTED FORMATS:
    .tar.bz2, .tar.gz, .tar.xz, .tar
    .bz2, .gz, .xz
    .zip, .7z
    .Z (compress)
    .tbz2, .tgz

EXAMPLES:
    extract archive.tar.gz
    extract archive.tar.gz /tmp/extracted
    extract --list archive.zip
EOF
}

# List archive contents
list_archive() {
    local file="$1"

    # Use helper if available, fallback to manual check
    if declare -f require_file &>/dev/null; then
        require_file "$file"
    elif [[ ! -f $file ]]; then
        echo "Error: File '$file' does not exist" >&2
        return 1
    fi

    echo "Contents of '$file':"
    case "$file" in
    *.tar.bz2 | *.tbz2)
        tar -tjf "$file" | head -20
        ;;
    *.tar.gz | *.tgz)
        tar -tzf "$file" | head -20
        ;;
    *.tar.xz)
        tar -tJf "$file" | head -20
        ;;
    *.tar)
        tar -tf "$file" | head -20
        ;;
    *.zip)
        unzip -l "$file" | head -20
        ;;
    *.7z)
        7z l "$file" | head -20
        ;;
    *.bz2 | *.gz | *.xz | *.Z)
        echo "Single file archive - would extract to: $(basename "$file" | sed 's/\.[^.]*$//')"
        ;;
    *)
        echo "Error: Unsupported archive format for listing" >&2
        return 1
        ;;
    esac
}

# Extract archive with format detection
extract_archive() {
    local file="$1"
    local destination="${2:-.}"

    # Validate input file
    if [[ ! -f $file ]]; then
        echo "Error: File '$file' does not exist" >&2
        return 1
    fi

    # Create destination directory if specified and doesn't exist
    if [[ $destination != "." && ! -d $destination ]]; then
        echo "Creating destination directory: $destination"
        mkdir -p "$destination"
    fi

    # Change to destination directory if specified
    if [[ $destination != "." ]]; then
        pushd "$destination" >/dev/null
    fi

    # Store original file path for extraction
    local original_file
    if [[ $destination != "." ]]; then
        original_file="$(realpath "$1")"
    else
        original_file="$file"
    fi

    echo "Extracting '$file'..."

    # Extract based on file extension
    case "$file" in
    *.tar.bz2 | *.tbz2)
        if command -v pv >/dev/null; then
            pv "$original_file" | tar xjf -
        else
            tar xjf "$original_file"
        fi
        ;;
    *.tar.gz | *.tgz)
        if command -v pv >/dev/null; then
            pv "$original_file" | tar xzf -
        else
            tar xzf "$original_file"
        fi
        ;;
    *.tar.xz)
        if command -v pv >/dev/null; then
            pv "$original_file" | tar xJf -
        else
            tar xJf "$original_file"
        fi
        ;;
    *.tar)
        if command -v pv >/dev/null; then
            pv "$original_file" | tar xf -
        else
            tar xf "$original_file"
        fi
        ;;
    *.bz2)
        bunzip2 -k "$original_file"
        ;;
    *.gz)
        if [[ $original_file == *.tar.gz ]]; then
            # This should have been caught above, but just in case
            tar xzf "$original_file"
        else
            gunzip -k "$original_file"
        fi
        ;;
    *.xz)
        if [[ $original_file == *.tar.xz ]]; then
            # This should have been caught above, but just in case
            tar xJf "$original_file"
        else
            xz -dk "$original_file"
        fi
        ;;
    *.zip)
        unzip -q "$original_file"
        ;;
    *.7z)
        7z x "$original_file"
        ;;
    *.Z)
        uncompress -f "$original_file"
        ;;
    *.rar)
        if command -v unrar >/dev/null; then
            unrar x "$original_file"
        else
            echo "Error: unrar not installed. Install with: brew install unrar" >&2
            return 1
        fi
        ;;
    *.deb)
        if command -v ar >/dev/null; then
            ar x "$original_file"
        else
            echo "Error: ar not available for .deb extraction" >&2
            return 1
        fi
        ;;
    *)
        echo "Error: Unsupported archive format for '$file'" >&2
        echo "Supported: .tar.gz, .tar.bz2, .tar.xz, .tar, .zip, .7z, .gz, .bz2, .xz, .Z" >&2
        return 1
        ;;
    esac

    # Return to original directory if we changed
    if [[ $destination != "." ]]; then
        popd >/dev/null
    fi

    echo "✓ Extraction completed successfully"

    # Show what was extracted
    if [[ $destination != "." ]]; then
        echo "Extracted to: $destination"
        echo "Contents:"
        find "$destination" -maxdepth 1 -type f -o -type d | head -10
    else
        echo "Contents extracted to current directory"
    fi
}

# Check for required tools
check_dependencies() {
    local missing_tools=()

    # Check for common extraction tools
    local tools=("tar" "unzip" "gunzip" "bunzip2")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    # Warn about optional but useful tools
    if ! command -v 7z >/dev/null; then
        echo "Info: 7z not found. Install with 'brew install p7zip' for .7z support" >&2
    fi

    if ! command -v pv >/dev/null; then
        echo "Info: pv not found. Install with 'brew install pv' for progress bars" >&2
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "Error: Missing required tools: ${missing_tools[*]}" >&2
        echo "Install missing tools and try again" >&2
        return 1
    fi
}

# Main function
main() {
    # Check dependencies first
    if ! check_dependencies; then
        exit 1
    fi

    # Parse arguments
    case "${1:-}" in
    -h | --help)
        show_usage
        exit 0
        ;;
    -l | --list)
        if [[ $# -lt 2 ]]; then
            echo "Error: --list requires a file argument" >&2
            show_usage >&2
            exit 1
        fi
        list_archive "$2"
        ;;
    "")
        echo "Error: No file specified" >&2
        show_usage >&2
        exit 1
        ;;
    -*)
        echo "Error: Unknown option '$1'" >&2
        show_usage >&2
        exit 1
        ;;
    *)
        extract_archive "$@"
        ;;
    esac
}

# Run main function with all arguments
main "$@"
