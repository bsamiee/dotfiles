#!/usr/bin/env bash
# Title         : audit-tools.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : bin/audit-tools.sh
# ---------------------------------------
# Comprehensive tool audit with detailed table output (optimized version)

set -uo pipefail

# Colors using associative array
declare -rA COLORS=(
    [R]='\033[0;31m' [G]='\033[0;32m' [B]='\033[0;34m'
    [Y]='\033[1;33m' [C]='\033[0;36m' [M]='\033[0;35m'
    [BOLD]='\033[1m' [NC]='\033[0m'
)

# Package manager configurations - data-driven approach
declare -A PM_CMDS=(
    [brew_check]="command -v brew"
    [brew_version]="brew --version | head -1 | cut -d' ' -f2"
    [brew_count]="brew list 2>/dev/null | wc -l | xargs"
    [brew_formulas]="brew list --formula 2>/dev/null | wc -l | xargs"
    [brew_casks]="brew list --cask 2>/dev/null | wc -l | xargs"

    [nix_check]="command -v nix"
    [nix_version]="nix --version | awk '{print \$NF}'"
    [nix_count]="nix profile list 2>/dev/null | wc -l | xargs"

    [npm_check]="command -v npm"
    [npm_version]="npm --version"
    [npm_count]="npm list -g --depth=0 2>/dev/null | tail -n +2 | wc -l | xargs"

    [pip_check]="command -v pip3"
    [pip_version]="pip3 --version | cut -d' ' -f2"
    [pip_count]="pip3 list 2>/dev/null | tail -n +3 | wc -l | xargs"

    [cargo_check]="command -v cargo"
    [cargo_version]="cargo --version | cut -d' ' -f2"
    [cargo_count]="cargo install --list 2>/dev/null | grep -c ':$' || echo 0"

    [gem_check]="command -v gem"
    [gem_version]="gem --version"
    [gem_count]="gem list --local 2>/dev/null | wc -l | xargs"

    [pipx_check]="command -v pipx"
    [pipx_version]="pipx --version"
    [pipx_count]="pipx list --short 2>/dev/null | wc -l | xargs"
)

# Display names
declare -rA PM_NAMES=(
    [brew]="Homebrew" [nix]="Nix" [npm]="NPM" [pip]="Pip"
    [cargo]="Cargo" [gem]="RubyGems" [pipx]="Pipx"
)

# Parse arguments
MODE="summary"
MANAGER=""
while [[ $# -gt 0 ]]; do
    case $1 in
    -d | --detail*)
        MODE="detail"
        shift
        ;;
    -m | --manager)
        MODE="manager"
        MANAGER="$2"
        shift 2
        ;;
    -s | --system)
        MODE="system"
        shift
        ;;
    -n | --network)
        MODE="network"
        shift
        ;;
    -p | --processes)
        MODE="processes"
        shift
        ;;
    -h | --help)
        cat <<-EOF
			Usage: $(basename "$0") [OPTIONS]

			Options:
			  -d, --detail     Show detailed table of all installed packages
			  -m, --manager    Show details for specific package manager
			                   Options: brew, nix, npm, pip, cargo, gem, pipx
			  -s, --system     Show comprehensive system information
			  -n, --network    Show network configuration and connectivity
			  -p, --processes  Show running processes and resource usage
			  -h, --help       Show this help message

			Examples:
			  $(basename "$0")              # Summary view
			  $(basename "$0") -d           # Detailed tables for all managers
			  $(basename "$0") -m brew      # Detailed view for Homebrew only
			  $(basename "$0") -s           # System information
			  $(basename "$0") -n           # Network diagnostics
			  $(basename "$0") -p           # Process information
		EOF
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use -h for help"
        exit 1
        ;;
    esac
done

# Temp directory for parallel results
TEMP_DIR=$(mktemp -d)
readonly TEMP_DIR
trap 'rm -rf "$TEMP_DIR"' EXIT

# Display functions
print_header() {
    printf "\n${COLORS[B]}%56s${COLORS[NC]}\n" | tr ' ' '━'
    echo -e "${COLORS[G]}  $1${COLORS[NC]}"
    printf "${COLORS[B]}%56s${COLORS[NC]}\n" | tr ' ' '━'
}

print_section() { echo -e "\n${COLORS[Y]}▶ $1${COLORS[NC]}"; }

print_table_header() {
    printf "${COLORS[BOLD]}%-30s %-15s %-40s${COLORS[NC]}\n" "$1" "$2" "$3"
    printf "%-30s %-15s %-40s\n" "$(printf '%.30s' '------------------------------')" \
        "$(printf '%.15s' '---------------')" "$(printf '%.40s' '----------------------------------------')"
}

# Generic detail collector function - replaces 6 separate functions
get_details() {
    local pm=$1
    local output_file="$TEMP_DIR/${pm}_details"

    # Clear the file for this package manager
    true >"$output_file"

    case $pm in
    brew)
        if eval "${PM_CMDS[brew_check]}" &>/dev/null; then
            {
                echo "FORMULAS"
                brew list --formula --versions 2>/dev/null | while read -r line; do
                    name=${line%% *}
                    version=${line#* }
                    version=${version%% *}
                    printf "%-30s %-15s %-40s\n" "$name" "$version" "$(brew --prefix)/opt/$name"
                done
                echo "CASKS"
                brew list --cask 2>/dev/null | while read -r cask; do
                    version=$(brew info --cask "$cask" 2>/dev/null | head -3 | grep -E "^$cask:" | sed 's/.*: //' | cut -d' ' -f1 || echo "latest")
                    printf "%-30s %-15s %-40s\n" "$cask" "$version" "/Applications"
                done
            } >"$output_file" 2>/dev/null
        fi
        ;;

    npm)
        if eval "${PM_CMDS[npm_check]}" &>/dev/null; then
            npm list -g --depth=0 2>/dev/null | tail -n +2 | while read -r line; do
                # Parse npm output format: ├── package@version or ├── @scope/package@version
                # Remove the tree characters
                line="${line#*── }"
                pkg="$line"
                if [[ -n $pkg && $pkg != *"UNMET"* && $pkg != *"empty"* ]]; then
                    # Handle both regular and scoped packages
                    if [[ $pkg == *"@"* ]]; then
                        # Extract name and version from package@version format
                        name="${pkg%@*}"
                        version="${pkg##*@}"
                    else
                        name="$pkg"
                        version="unknown"
                    fi
                    [[ -n $name ]] &&
                        printf "%-30s %-15s %-40s\n" "$name" "$version" "$(npm root -g)/${name#@*/}"
                fi
            done >"$output_file" 2>/dev/null
        fi
        ;;

    pip)
        if eval "${PM_CMDS[pip_check]}" &>/dev/null; then
            pip3 list --format=freeze 2>/dev/null | while read -r line; do
                if [[ $line == *"=="* ]]; then
                    name=${line%%==*}
                    version=${line##*==}
                    printf "%-30s %-15s %-40s\n" "$name" "$version" "site-packages"
                fi
            done >"$output_file" 2>/dev/null
        fi
        ;;

    cargo)
        eval "${PM_CMDS[cargo_check]}" &>/dev/null &&
            cargo install --list 2>/dev/null | grep -E "^[a-z].*:$" | sed 's/:$//' |
            while read -r line; do
                name=${line%% *}
                version=$(echo "$line" | grep -oE "v[0-9]+\.[0-9]+\.[0-9]+" || echo "unknown")
                printf "%-30s %-15s %-40s\n" "$name" "$version" "$HOME/.cargo/bin/$name"
            done >"$output_file" 2>/dev/null
        ;;

    nix)
        if eval "${PM_CMDS[nix_check]}" &>/dev/null; then
            {
                nix profile list 2>/dev/null | while read -r _ name _; do
                    [[ $name =~ ^[a-zA-Z] ]] &&
                        printf "%-30s %-15s %-40s\n" "${name##*.}" "profile" "/nix/store/..."
                done
                [[ -d "$HOME/.nix-profile/bin" ]] &&
                    find "$HOME/.nix-profile/bin" -type l 2>/dev/null | while read -r link; do
                        printf "%-30s %-15s %-40s\n" "$(basename "$link")" "home-manager" "$(readlink "$link")" | head -20
                    done
            } >"$output_file" 2>/dev/null
        fi
        ;;

    gem)
        eval "${PM_CMDS[gem_check]}" &>/dev/null &&
            gem list --local 2>/dev/null | while read -r line; do
                name=${line%% *}
                version=$(echo "$line" | sed 's/.*(\(.*\))/\1/' | cut -d',' -f1)
                location=$(gem which "$name" 2>/dev/null | xargs dirname 2>/dev/null || echo "gem path")
                printf "%-30s %-15s %-40s\n" "$name" "$version" "$location"
            done >"$output_file" 2>/dev/null
        ;;
    esac
}

# Summary view
show_summary() {
    print_header "PACKAGE MANAGERS"

    for pm in brew nix npm pip cargo gem pipx; do
        if eval "${PM_CMDS[${pm}_check]}" &>/dev/null; then
            print_section "${PM_NAMES[${pm/pip/pip}]}"
            echo "  Version: $(eval "${PM_CMDS[${pm/pip3/pip}_version]}" 2>/dev/null)"

            case $pm in
            brew)
                echo "  Formulas: $(eval "${PM_CMDS[brew_formulas]}")"
                echo "  Casks: $(eval "${PM_CMDS[brew_casks]}")"
                ;;
            nix)
                echo "  Profiles: $(eval "${PM_CMDS[nix_count]}")"
                [[ -d "$HOME/.nix-profile" ]] && echo "  Home-manager: Active"
                ;;
            npm) echo "  Global packages: $(eval "${PM_CMDS[npm_count]}")" ;;
            pip) echo "  Packages: $(eval "${PM_CMDS[pip_count]}")" ;;
            cargo) echo "  Crates: $(eval "${PM_CMDS[cargo_count]}")" ;;
            gem) echo "  Gems: $(eval "${PM_CMDS[gem_count]}")" ;;
            pipx) echo "  Apps: $(eval "${PM_CMDS[pipx_count]}")" ;;
            esac
        fi
    done

    print_header "DEVELOPMENT TOOLS"
    print_section "Active Versions"

    {
        command -v git &>/dev/null && echo "Git:$(git --version | cut -d' ' -f3)"
        command -v python3 &>/dev/null && echo "Python:$(python3 --version | cut -d' ' -f2)"
        command -v node &>/dev/null && echo "Node:$(node --version)"
        command -v rustc &>/dev/null && echo "Rust:$(rustc --version | cut -d' ' -f2)"
        command -v docker &>/dev/null && echo "Docker:$(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
        command -v go &>/dev/null && echo "Go:$(go version | cut -d' ' -f3)"
        command -v lua &>/dev/null && echo "Lua:$(lua -v 2>&1 | cut -d' ' -f2)"
        command -v nix &>/dev/null && echo "Nix:$(nix --version | cut -d' ' -f3)"
    } | column -t -s':' | sed 's/^/  /'
}

# Display package details from temp file
display_packages() {
    local pm=$1
    local file="$TEMP_DIR/${pm}_details"
    local limit=${2:-0}

    [[ ! -f $file || ! -s $file ]] && return 1

    print_section "${PM_NAMES[$pm]} Packages"

    if [[ $pm == "brew" ]]; then
        if grep -q "FORMULAS" "$file"; then
            echo -e "\n${COLORS[C]}Formulas:${COLORS[NC]}"
            print_table_header "Package" "Version" "Location"
            sed -n '/FORMULAS/,/CASKS/p' "$file" | grep -v "FORMULAS\|CASKS" 2>/dev/null
        fi
        if grep -q "CASKS" "$file"; then
            echo -e "\n${COLORS[C]}Casks:${COLORS[NC]}"
            print_table_header "Application" "Version" "Location"
            sed -n '/CASKS/,$p' "$file" | grep -v "CASKS"
        fi
    else
        print_table_header "${pm^}" "Version" "Location"
        if [[ $limit -gt 0 ]]; then
            head -n "$limit" "$file"
            local total
            total=$(wc -l <"$file")
            [[ $total -gt $limit ]] && echo "... and $((total - limit)) more"
        else
            cat "$file"
        fi
    fi
}

# Detail view
show_details() {
    show_summary
    echo -e "\n${COLORS[G]}Collecting detailed package information...${COLORS[NC]}"

    # Launch collectors in parallel with proper file isolation
    # Store PIDs to ensure we wait for all specific jobs
    local pids=()
    for pm in brew nix npm pip cargo gem; do
        get_details "$pm" &
        pids+=($!) # Store the PID of the last background job
    done

    # Wait for all specific background jobs to complete
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null
    done

    print_header "INSTALLED PACKAGES - DETAILED VIEW"

    # Display with limits where appropriate
    display_packages brew
    display_packages nix 30
    display_packages npm
    display_packages pip 20
    display_packages cargo
    display_packages gem 20
}

# Manager-specific view
show_manager() {
    local pm="${1,,}"
    if [[ ! " brew nix npm pip cargo gem " =~ $pm ]]; then
        echo "Unknown manager: $pm"
        exit 1
    fi

    get_details "${pm/homebrew/brew}"

    local file="$TEMP_DIR/${pm/homebrew/brew}_details"
    if [[ -f $file && -s $file ]]; then
        print_header "${PM_NAMES[${pm/homebrew/brew}]} PACKAGES"
        echo -e "${COLORS[C]}Total: $(wc -l <"$file") packages${COLORS[NC]}"
        display_packages "${pm/homebrew/brew}"
    else
        echo "${PM_NAMES[${pm/homebrew/brew}]} not installed or no packages found"
    fi
}

# System information view
show_system() {
    print_header "SYSTEM INFORMATION"

    print_section "Hardware & OS"
    {
        echo "Hostname:$(hostname -s)"
        echo "User:$(whoami)"
        echo "Uptime:$(uptime | awk -F'up ' '{print $2}' | awk -F', ' '{print $1}')"

        # macOS specific info
        if [[ $OSTYPE == "darwin"* ]]; then
            echo "macOS:$(sw_vers -productVersion)"
            echo "Build:$(sw_vers -buildVersion)"

            # Hardware info
            local machine_model
            machine_model=$(system_profiler SPHardwareDataType 2>/dev/null | awk '/Model Name/ {print $3" "$4" "$5}' | head -1)
            [[ -n $machine_model ]] && echo "Model:$machine_model"

            local chip_info
            chip_info=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown CPU")
            echo "CPU:$chip_info"

            local memory_info
            memory_info=$(system_profiler SPHardwareDataType 2>/dev/null | awk '/Memory/ {print $2" "$3}' | head -1)
            [[ -n $memory_info ]] && echo "Memory:$memory_info"
        else
            echo "OS:$(uname -s) $(uname -r)"
            echo "Architecture:$(uname -m)"
        fi
    } | column -t -s':' | sed 's/^/  /'

    print_section "Storage"
    echo "  Disk Usage:"
    df -h | grep -E '^(/dev/|Filesystem)' | column -t | sed 's/^/    /'

    # Show largest directories in home
    echo
    echo "  Home Directory Usage:"
    du -sh ~/* 2>/dev/null | sort -hr | head -10 | sed 's/^/    /'

    print_section "Environment"
    {
        echo "Shell:$SHELL"
        echo "Terminal:${TERM_PROGRAM:-$TERM}"
        [[ -n $TMUX ]] && echo "Tmux:Active"
        [[ -n $SSH_CONNECTION ]] && echo "SSH:Active"
        echo "PATH entries:$(echo "$PATH" | tr ':' '\n' | wc -l | xargs)"
    } | column -t -s':' | sed 's/^/  /'

    print_section "Security & Permissions"
    {
        echo "UID:$(id -u)"
        echo "GID:$(id -g)"
        echo "Groups:$(id -Gn | tr ' ' ',' | cut -c1-40)"

        # macOS specific security info
        if [[ $OSTYPE == "darwin"* ]]; then
            local sip_status
            sip_status=$(csrutil status 2>/dev/null | awk '{print $NF}' | tr -d '.')
            [[ -n $sip_status ]] && echo "SIP:$sip_status"

            local gatekeeper_status
            gatekeeper_status=$(spctl --status 2>/dev/null | awk '{print $2}')
            [[ -n $gatekeeper_status ]] && echo "Gatekeeper:$gatekeeper_status"
        fi
    } | column -t -s':' | sed 's/^/  /'
}

# Network information view
show_network() {
    print_header "NETWORK INFORMATION"

    print_section "Network Interfaces"
    if [[ $OSTYPE == "darwin"* ]]; then
        networksetup -listallhardwareports 2>/dev/null | grep -A1 "Wi-Fi\|Ethernet" | grep -E "(Wi-Fi|Ethernet|Device)" | sed 's/^/  /'
    else
        ip addr show | grep -E "^[0-9]|inet " | sed 's/^/  /'
    fi

    print_section "Connectivity"
    {
        # Local IP
        local local_ip
        if [[ $OSTYPE == "darwin"* ]]; then
            local_ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "Not connected")
        else
            local_ip=$(hostname -I | awk '{print $1}' || echo "Not connected")
        fi
        echo "Local IP:$local_ip"

        # Public IP (with timeout)
        local public_ip
        public_ip=$(timeout 3 curl -s https://ipinfo.io/ip 2>/dev/null || echo "Unable to reach")
        echo "Public IP:$public_ip"

        # WiFi info (macOS)
        if [[ $OSTYPE == "darwin"* ]]; then
            local wifi_network
            wifi_network=$(networksetup -getairportnetwork en0 2>/dev/null | cut -d: -f2 | xargs || echo "Not connected")
            echo "WiFi:$wifi_network"
        fi

        # DNS servers
        local dns_servers
        if [[ $OSTYPE == "darwin"* ]]; then
            dns_servers=$(scutil --dns 2>/dev/null | awk '/nameserver/ {print $3}' | head -2 | tr '\n' ',' | sed 's/,$//')
        else
            dns_servers=$(awk '/nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null | head -2 | tr '\n' ',' | sed 's/,$//')
        fi
        [[ -n $dns_servers ]] && echo "DNS:$dns_servers"
    } | column -t -s':' | sed 's/^/  /'

    print_section "Active Connections"
    echo "  Listening Ports:"
    lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null | head -10 | awk 'NR>1 {printf "    %-20s %-10s %s\n", $1, $3, $9}' || echo "    No listening ports found"

    print_section "Network Test"
    echo "  Connectivity Test:"
    local test_hosts=("google.com" "github.com" "1.1.1.1")
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 2000 "$host" >/dev/null 2>&1; then
            echo "    ✓ $host: Reachable"
        else
            echo "    ✗ $host: Unreachable"
        fi
    done
}

# Process information view
show_processes() {
    print_header "PROCESS INFORMATION"

    print_section "Resource Usage"
    echo "  CPU Usage (Top 10):"
    if [[ $OSTYPE == "darwin"* ]]; then
        ps aux | sort -rk3 | head -11 | awk 'NR==1{printf "    %-8s %-8s %-8s %s\n", "USER", "CPU%", "MEM%", "COMMAND"} NR>1{printf "    %-8s %-8s %-8s %s\n", $1, $3"%", $4"%", $11}' | head -11
    else
        ps aux | sort -rk3 | head -11 | awk 'NR==1{printf "    %-8s %-8s %-8s %s\n", "USER", "CPU%", "MEM%", "COMMAND"} NR>1{printf "    %-8s %-8s %-8s %s\n", $1, $3"%", $4"%", $11}' | head -11
    fi

    echo
    echo "  Memory Usage (Top 10):"
    ps aux | sort -rk4 | head -11 | awk 'NR==1{printf "    %-8s %-8s %-8s %s\n", "USER", "CPU%", "MEM%", "COMMAND"} NR>1{printf "    %-8s %-8s %-8s %s\n", $1, $3"%", $4"%", $11}' | head -11

    print_section "Process Statistics"
    {
        echo "Total processes:$(ps aux | wc -l | xargs)"
        echo "Running processes:$(ps aux | awk '$8 ~ /R/ {count++} END {print count+0}')"
        echo "Sleeping processes:$(ps aux | awk '$8 ~ /S/ {count++} END {print count+0}')"
        echo "Zombie processes:$(ps aux | awk '$8 ~ /Z/ {count++} END {print count+0}')"
        echo "Current user processes:$(ps -u "$(whoami)" | wc -l | xargs)"
    } | column -t -s':' | sed 's/^/  /'

    print_section "System Load"
    if [[ $OSTYPE == "darwin"* ]]; then
        {
            local load_avg
            load_avg=$(uptime | awk -F'load average:' '{print $2}' | xargs)
            echo "Load average:$load_avg"

            local cpu_cores
            cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "Unknown")
            echo "CPU cores:$cpu_cores"

            # Memory info
            local memory_pressure
            memory_pressure=$(memory_pressure 2>/dev/null | tail -1 || echo "Unknown")
            echo "Memory pressure:$memory_pressure"
        } | column -t -s':' | sed 's/^/  /'
    else
        {
            local load_avg
            load_avg=$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null || echo "Unknown")
            echo "Load average:$load_avg"

            local cpu_cores
            cpu_cores=$(nproc 2>/dev/null || echo "Unknown")
            echo "CPU cores:$cpu_cores"
        } | column -t -s':' | sed 's/^/  /'
    fi

    print_section "Process Tree (Sample)"
    if command -v pstree >/dev/null 2>&1; then
        echo "  Process hierarchy:"
        pstree -p | head -20 | sed 's/^/    /'
    else
        echo "  Process hierarchy (ps format):"
        ps -eo pid,ppid,user,comm | head -20 | sed 's/^/    /'
    fi
}

# Main execution
echo -e "${COLORS[G]}${COLORS[BOLD]}Tool Ecosystem Audit${COLORS[NC]}"
echo -e "${COLORS[C]}$(date '+%Y-%m-%d %H:%M:%S')${COLORS[NC]} | ${COLORS[C]}$USER@$(hostname -s)${COLORS[NC]}"

case "$MODE" in
summary)
    show_summary
    echo -e "\n${COLORS[C]}Options:${COLORS[NC]}\n  Use -d for detailed package tables\n  Use -m <manager> for specific manager details\n  Use -s for system information\n  Use -n for network diagnostics\n  Use -p for process information"
    ;;
detail) show_details ;;
manager) show_manager "$MANAGER" ;;
system) show_system ;;
network) show_network ;;
processes) show_processes ;;
esac

echo -e "\n${COLORS[G]}✓ Audit complete${COLORS[NC]}"
