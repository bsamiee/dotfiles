#!/usr/bin/env bash
# Title         : file-ops.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : bin/file-ops.sh
# ---------------------------------------
# Advanced file operations leveraging modern CLI tools

set -euo pipefail

# Source common functions if available
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
# shellcheck source=/dev/null
[[ -f "${DOTFILES}/lib/common.sh" ]] && source "${DOTFILES}/lib/common.sh"

# --- Interactive File Operations -------------------------------------------

# Interactive delete with preview
# Uses fd to find files, fzf to select, and trash-put for safe deletion
interactive_delete() {
    local search_path="${1:-.}"
    shift || true

    echo "Select files to delete (use TAB for multi-select, ENTER to confirm):"

    local files
    files=$(fd --type f "$@" "$search_path" 2>/dev/null |
        fzf --multi \
            --preview 'bat --color=always {} 2>/dev/null || cat {}' \
            --preview-window=right:60% \
            --header="TAB: select, ENTER: delete selected, ESC: cancel")

    if [[ -n $files ]]; then
        echo "Files to be deleted:"
        echo "$files"

        # Safety check for each file
        local safe_files=""
        while IFS= read -r file; do
            if is_safe_to_delete "$file"; then
                safe_files="${safe_files}${file}\n"
            else
                echo "Warning: Skipping protected file: $file"
            fi
        done <<<"$files"

        if [[ -n $safe_files ]]; then
            read -p "Confirm deletion? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "$safe_files" | xargs -I {} trash-put "{}"
                echo "Files moved to trash. Use 'rmrestore' to recover."
            else
                echo "Deletion cancelled."
            fi
        else
            echo "No safe files to delete."
        fi
    else
        echo "No files selected."
    fi
}

# Bulk rename using fd and sd
# Example: bulk_rename "*.txt" "old" "new"
bulk_rename() {
    local pattern="${1}"
    local old_text="${2}"
    local new_text="${3}"

    if [[ $# -lt 3 ]]; then
        echo "Usage: bulk_rename <file_pattern> <old_text> <new_text>"
        echo "Example: bulk_rename '*.txt' 'old' 'new'"
        return 1
    fi

    echo "Preview of changes:"
    fd --glob "$pattern" -x echo "{} -> {}" | sd "$old_text" "$new_text"

    read -p "Proceed with rename? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        fd --glob "$pattern" -x bash -c "mv \"\$1\" \"\$(echo \"\$1\" | sd \"$old_text\" \"$new_text\")\"" _ {}
        echo "Rename complete."
    else
        echo "Rename cancelled."
    fi
}

# Find duplicate files by content (using checksums)
find_duplicates() {
    local search_path="${1:-.}"

    echo "Finding duplicate files in $search_path..."

    # Create temporary file for checksums
    local tmpfile
    tmpfile=$(mktemp)
    trap 'rm -f $tmpfile' EXIT

    # Calculate checksums for all files
    fd --type f . "$search_path" -x sha256sum {} \; >"$tmpfile" 2>/dev/null

    # Find and display duplicates
    awk '{print $1}' "$tmpfile" | sort | uniq -d | while read -r checksum; do
        echo "Duplicate files with checksum: $checksum"
        grep "^$checksum" "$tmpfile" | awk '{$1=""; print "  "$0}'
        echo
    done
}

# Smart copy with progress for large files
# Automatically uses fcp for files over 100MB, regular cp for smaller
smart_copy() {
    local source="${1}"
    local dest="${2}"

    if [[ ! -e $source ]]; then
        echo "Error: Source '$source' does not exist"
        return 1
    fi

    # Get size using helper function
    local size_str
    size_str=$(get_file_size "$source")

    # Parse size to determine if it's large (over 100MB)
    local size_num
    local size_unit
    size_num="${size_str//[^0-9.]/}"
    size_unit="${size_str//[0-9.]/}"

    # Check if file is large (simplistic check for G or > 100M)
    local use_fcp=false
    if [[ $size_unit == "G" ]]; then
        use_fcp=true
    elif [[ $size_unit == "M" ]]; then
        # Check if over 100M
        if (($(echo "$size_num > 100" | bc -l))); then
            use_fcp=true
        fi
    fi

    # Use fcp for large files/dirs, regular cp for smaller
    if [[ $use_fcp == true ]]; then
        echo "Large file/directory detected ($size_str). Using fast copy..."
        if command -v fcp &>/dev/null; then
            fcp "$source" "$dest"
        else
            cp -r "$source" "$dest"
        fi
    else
        cp -r "$source" "$dest"
    fi
}

# Find and preview files interactively
find_preview() {
    local search_term="${1:-}"

    fd --type f --hidden "$search_term" |
        fzf --preview 'bat --color=always {} 2>/dev/null || cat {}' \
            --preview-window=right:60% \
            --bind='enter:execute(nvim {})' \
            --bind='ctrl-o:execute(open {})' \
            --header="ENTER: edit, CTRL-O: open, ESC: exit"
}

# Clean old files safely (with confirmation)
clean_old_files() {
    local days="${1:-30}"
    local path="${2:-.}"

    echo "Finding files older than $days days in $path..."

    local old_files
    old_files=$(fd --changed-before "${days}d" --type f . "$path" 2>/dev/null)

    if [[ -z $old_files ]]; then
        echo "No files older than $days days found."
        return 0
    fi

    echo "Files to be deleted:"
    echo "$old_files" | head -20

    local count
    count=$(echo "$old_files" | wc -l)
    echo "Total: $count files"

    read -p "Move these files to trash? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$old_files" | xargs -I {} trash-put "{}"
        echo "Files moved to trash. Use 'rmrestore' to recover."
    else
        echo "Cleanup cancelled."
    fi
}

# Create backup using XDG-compliant location
backup_file() {
    local file="${1}"
    local backup_dir="${2:-}"

    if [[ -z $file ]]; then
        echo "Usage: $(basename "$0") backup <file> [backup_dir]"
        return 1
    fi

    if [[ -n $backup_dir ]]; then
        ensure_backup "$file" "$backup_dir"
    else
        ensure_backup "$file"
    fi
}

# --- Main Command Handler ---------------------------------------------------

show_usage() {
    cat <<EOF
Usage: $(basename "$0") <command> [options]

Commands:
    delete, del     Interactive file deletion with preview
    rename, ren     Bulk rename files
    duplicates, dup Find duplicate files by content
    copy, cp        Smart copy with automatic method selection
    preview, prev   Find and preview files interactively
    clean           Clean old files safely
    backup, bak     Create timestamped backup (XDG-compliant)
    
Examples:
    $(basename "$0") delete "*.tmp"      # Interactive delete temp files
    $(basename "$0") rename "*.txt" old new  # Rename files
    $(basename "$0") duplicates ./photos     # Find duplicate photos
    $(basename "$0") clean 60 ./downloads    # Clean files older than 60 days
    $(basename "$0") backup important.conf  # Backup to ~/.local/share/backups
    
EOF
}

# Parse command
case "${1:-}" in
delete | del)
    shift
    interactive_delete "$@"
    ;;
rename | ren)
    shift
    bulk_rename "$@"
    ;;
duplicates | dup)
    shift
    find_duplicates "$@"
    ;;
copy | cp)
    shift
    smart_copy "$@"
    ;;
preview | prev)
    shift
    find_preview "$@"
    ;;
clean)
    shift
    clean_old_files "$@"
    ;;
backup | bak)
    shift
    backup_file "$@"
    ;;
-h | --help | help)
    show_usage
    ;;
*)
    echo "Error: Unknown command '${1:-}'"
    echo
    show_usage
    exit 1
    ;;
esac
