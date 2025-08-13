#!/usr/bin/env bash

# Title         : shell-analysis.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : bin/shell-analysis.sh
# ---------------------------------------
# Shell history analysis and utility functions

set -euo pipefail

# Display usage information
show_usage() {
  cat <<'EOF'
shell-analysis - Shell History Analysis and Utilities

USAGE:
    shell-analysis hist [count]    # Command frequency analysis
    shell-analysis urlencode       # URL encode from stdin
    shell-analysis urldecode       # URL decode from stdin
    shell-analysis --help          # Show this help

EXAMPLES:
    shell-analysis hist            # Top 20 most frequent commands
    shell-analysis hist 10         # Top 10 most frequent commands
    echo "hello world" | shell-analysis urlencode    # URL encode text
    echo "hello%20world" | shell-analysis urldecode  # URL decode text

DESCRIPTION:
    Provides shell history analysis and utility functions that were
    previously implemented as complex inline functions in aliases.
    Offers better error handling and more maintainable implementations.
EOF
}

# Command frequency analysis
analyze_history() {
  local count="${1:-20}"

  # Validate count parameter
  if ! [[ $count =~ ^[0-9]+$ ]] || [[ $count -lt 1 ]]; then
    echo "Error: Count must be a positive integer" >&2
    return 1
  fi

  # Check if history command is available
  if ! command -v history >/dev/null 2>&1; then
    echo "Error: history command not available" >&2
    return 1
  fi

  # Check if required tools are available
  for tool in awk rg column sort nl head; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      echo "Error: Required tool '$tool' not found" >&2
      return 1
    fi
  done

  echo "Top $count commands by frequency:"
  echo "================================="

  # Enhanced version of the original hist function with better error handling
  history | awk '
    {
        # Skip empty lines and lines starting with numbers only
        if (NF >= 2) {
            cmd = $2
            # Handle commands with arguments - take only the base command
            gsub(/[[:space:]].*$/, "", cmd)
            if (cmd != "" && cmd !~ /^[0-9]+$/) {
                CMD[cmd]++
                count++
            }
        }
    }
    END {
        if (count > 0) {
            for (a in CMD) {
                percentage = CMD[a]/count*100
                printf "%.0f %.1f%% %s\n", CMD[a], percentage, a
            }
        } else {
            print "No commands found in history"
        }
    }' |
    rg -v '^\.' |
    column -t |
    sort -nr |
    nl -w3 -s'. ' |
    head -n "$count"
}

# URL encode from stdin
url_encode() {
  # Check if Python is available
  if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 not found" >&2
    return 1
  fi

  # Read from stdin with timeout to prevent hanging
  if [[ -t 0 ]]; then
    echo "Error: No input provided. Please pipe text to this command." >&2
    echo "Example: echo 'hello world' | shell-analysis urlencode" >&2
    return 1
  fi

  python3 -c "
import sys
import urllib.parse

try:
    input_text = sys.stdin.read().strip()
    if input_text:
        encoded = urllib.parse.quote(input_text, safe='')
        print(encoded)
    else:
        print('Error: Empty input', file=sys.stderr)
        sys.exit(1)
except KeyboardInterrupt:
    print('Operation cancelled', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"
}

# URL decode from stdin
url_decode() {
  # Check if Python is available
  if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 not found" >&2
    return 1
  fi

  # Read from stdin with timeout to prevent hanging
  if [[ -t 0 ]]; then
    echo "Error: No input provided. Please pipe text to this command." >&2
    echo "Example: echo 'hello%20world' | shell-analysis urldecode" >&2
    return 1
  fi

  python3 -c "
import sys
import urllib.parse

try:
    input_text = sys.stdin.read().strip()
    if input_text:
        decoded = urllib.parse.unquote(input_text)
        print(decoded)
    else:
        print('Error: Empty input', file=sys.stderr)
        sys.exit(1)
except KeyboardInterrupt:
    print('Operation cancelled', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"
}

# Main function
main() {
  case "${1:-}" in
    -h | --help)
      show_usage
      exit 0
      ;;
    hist | history)
      shift
      analyze_history "$@"
      ;;
    urlencode | encode)
      url_encode
      ;;
    urldecode | decode)
      url_decode
      ;;
    "")
      echo "Error: No command specified" >&2
      show_usage >&2
      exit 1
      ;;
    *)
      echo "Error: Unknown command '$1'" >&2
      show_usage >&2
      exit 1
      ;;
  esac
}

# Run main function with all arguments
main "$@"
