#!/usr/bin/env bash
# Title         : qa-report.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : bin/qa-report.sh
# ---------------------------------------
# Unified quality assurance reporting for development tools

set -euo pipefail

# Source common helpers for system info
# shellcheck source=/dev/null
source "${DOTFILES:-$HOME/.dotfiles}/lib/common.sh" 2>/dev/null || true

# Display usage information
show_usage() {
    cat <<'EOF'
qa-report - Unified Quality Assurance Reporting

USAGE:
    qa-report nix [files...]       # Nix code quality report
    qa-report shell [files...]     # Shell script quality report
    qa-report docker               # Docker system report
    qa-report system               # System information report
    qa-report --help               # Show this help

EXAMPLES:
    qa-report nix                  # Report on all .nix files in current directory
    qa-report nix flake.nix        # Report on specific Nix file
    qa-report shell                # Report on all .sh files in current directory
    qa-report shell script.sh      # Report on specific shell script
    qa-report docker               # Docker system status report
    qa-report system               # Show system configuration info

DESCRIPTION:
    Provides comprehensive quality reports for different development tools
    with consistent formatting and error handling. Consolidates reporting
    functionality that was previously scattered across multiple alias files.
EOF
}

# Print section header with consistent formatting
print_section() {
    echo "=== $1 ==="
}

# Print section separator
print_separator() {
    echo
}

# Nix quality report
qa_report_nix() {
    local files=("${@:-.}")
    local exit_code=0

    print_section "Dead Code Analysis"
    if ! deadnix --hidden --no-underscore "${files[@]}" 2>/dev/null; then
        echo "ℹ No dead code found"
    fi

    print_separator
    print_section "Static Analysis"
    if ! statix check "${files[@]}" 2>/dev/null; then
        echo "ℹ No static issues found"
        exit_code=1
    fi

    print_separator
    print_section "Format Check"
    if ! nixfmt --check "${files[@]}" 2>/dev/null; then
        echo "ℹ Files need formatting"
        exit_code=1
    fi

    return $exit_code
}

# Shell script quality report
qa_report_shell() {
    local files=("${@:-*.sh}")
    local exit_code=0

    # Handle case where *.sh doesn't match any files
    if [[ ${files[0]} == "*.sh" ]] && [[ ! -f "*.sh" ]]; then
        mapfile -t files < <(find . -name "*.sh" -type f 2>/dev/null || echo)
        if [[ ${#files[@]} -eq 0 ]]; then
            echo "No shell files found in current directory"
            return 1
        fi
    fi

    print_section "Syntax Check"
    for file in "${files[@]}"; do
        if [[ -f $file ]]; then
            if ! bash -n "$file" 2>/dev/null; then
                echo "✗ Syntax errors in $file"
                exit_code=1
            else
                echo "✓ $file: syntax OK"
            fi
        fi
    done

    print_separator
    print_section "ShellCheck Issues"
    if ! shellcheck "${files[@]}" 2>/dev/null; then
        exit_code=1
    fi

    print_separator
    print_section "Format Check"
    if ! shfmt -ci -i 4 -d "${files[@]}" 2>/dev/null; then
        echo "ℹ Files need formatting"
        exit_code=1
    fi

    return $exit_code
}

# Docker system report
qa_report_docker() {
    print_section "System Usage"
    if ! docker system df 2>/dev/null; then
        echo "✗ Docker daemon not running or not accessible"
        return 1
    fi

    print_separator
    print_section "Containers"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null || {
        echo "✗ Failed to list containers"
        return 1
    }

    print_separator
    print_section "Images"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" 2>/dev/null || {
        echo "✗ Failed to list images"
        return 1
    }

    # Additional useful information
    print_separator
    print_section "Resource Usage"
    if docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemPerc}}" 2>/dev/null | head -10; then
        : # Success, no action needed
    else
        echo "ℹ No running containers to show stats for"
    fi
}

# Main function
main() {
    case "${1:-}" in
    -h | --help)
        show_usage
        exit 0
        ;;
    nix)
        shift
        qa_report_nix "$@"
        ;;
    shell)
        shift
        qa_report_shell "$@"
        ;;
    docker)
        qa_report_docker
        ;;
    system)
        if type show_system_info >/dev/null 2>&1; then
            show_system_info
        else
            echo "System information:" >&2
            echo "  User: $(whoami)" >&2
            echo "  Host: $(hostname -s)" >&2
            echo "  Arch: $(uname -m)" >&2
        fi
        ;;
    "")
        echo "Error: No report type specified" >&2
        show_usage >&2
        exit 1
        ;;
    *)
        echo "Error: Unknown report type '$1'" >&2
        show_usage >&2
        exit 1
        ;;
    esac
}

# Run main function with all arguments
main "$@"
