#!/usr/bin/env bash
# Title         : dev-env.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : bin/dev-env.sh
# ---------------------------------------
# Development environment launcher with smart detection and context switching

set -euo pipefail

# Display usage information
show_usage() {
    cat <<'EOF'
dev-env - Universal Development Environment Launcher

USAGE:
    dev-env [ENVIRONMENT] [COMMAND]
    dev-env --list
    dev-env --detect
    dev-env --help

ENVIRONMENTS:
    nix          Enter Nix development shell (default or .#dev)
    python       Enter Python development environment (.#python)  
    lua          Enter Lua development environment (.#lua)
    node         Enter Node.js development environment (.#node)
    rust         Enter Rust development environment (.#rust)
    go           Enter Go development environment (.#go)
    auto         Auto-detect environment from current directory

COMMANDS:
    repl         Start interactive REPL for environment
    eval         Evaluate expression in environment
    run          Run command in environment context
    shell        Enter interactive shell (default)
    test         Run tests in environment
    build        Build project in environment

EXAMPLES:
    dev-env                    # Auto-detect and enter development shell
    dev-env nix                # Enter Nix development shell
    dev-env python repl        # Start Python REPL
    dev-env lua eval "print('hello')"  # Evaluate Lua expression
    dev-env node run npm test  # Run npm test in Node environment
    dev-env --detect           # Show detected project type
    dev-env --list             # List available environments

ENVIRONMENT DETECTION:
    Auto-detection looks for:
    - flake.nix (Nix project)
    - package.json (Node.js project)
    - Cargo.toml (Rust project) 
    - go.mod (Go project)
    - pyproject.toml, setup.py (Python project)
    - rockspec files (Lua project)
    - .envrc (direnv configuration)
EOF
}

# Detect project type based on files in current directory
detect_project_type() {
    local detected=()

    # Check for various project indicators
    [[ -f "flake.nix" ]] && detected+=("nix")
    [[ -f "package.json" ]] && detected+=("node")
    [[ -f "Cargo.toml" ]] && detected+=("rust")
    [[ -f "go.mod" ]] && detected+=("go")
    [[ -f "pyproject.toml" || -f "setup.py" || -f "requirements.txt" ]] && detected+=("python")
    [[ -f "*.rockspec" ]] && detected+=("lua")

    # Check for .envrc which might indicate Nix project
    if [[ -f ".envrc" ]] && grep -q "use flake" .envrc 2>/dev/null; then
        [[ ! " ${detected[*]} " =~ " nix " ]] && detected+=("nix")
    fi

    # Return the detected types
    printf '%s\n' "${detected[@]}"
}

# List available development environments
list_environments() {
    echo "Available development environments:"
    echo

    # Check Nix environments
    if [[ -f "flake.nix" ]]; then
        echo "Nix environments (from flake.nix):"
        if command -v nix >/dev/null; then
            nix flake show 2>/dev/null | grep -E "devShells\." | sed 's/.*devShells\./  - /' | sed 's/:.*$//' || echo "  - default"
        else
            echo "  - default"
        fi
        echo
    fi

    # Check detected project types
    local detected
    mapfile -t detected < <(detect_project_type)
    if [[ ${#detected[@]} -gt 0 ]]; then
        echo "Detected project types:"
        printf '  - %s\n' "${detected[@]}"
        echo
    fi

    # Show standard environments
    echo "Standard environments:"
    echo "  - nix     (Nix development tools)"
    echo "  - python  (Python ecosystem)"
    echo "  - node    (Node.js ecosystem)"
    echo "  - lua     (Lua ecosystem)"
    echo "  - rust    (Rust ecosystem)"
    echo "  - go      (Go ecosystem)"
    echo "  - auto    (Auto-detect from current directory)"
}

# Get the best shell for an environment
get_shell_for_env() {
    local env="$1"

    case "$env" in
    nix)
        if command -v zsh >/dev/null; then
            echo "zsh"
        elif command -v bash >/dev/null; then
            echo "bash"
        else
            echo "sh"
        fi
        ;;
    python)
        # Check if we're in a Python project with specific shell preferences
        if [[ -f "pyproject.toml" ]] && grep -q "ipython" pyproject.toml 2>/dev/null; then
            echo "ipython"
        else
            echo "python3"
        fi
        ;;
    lua)
        # Prefer luajit if project has luajit config
        if [[ -f ".luajitrc" || -f "luajit.conf" ]]; then
            echo "luajit"
        else
            echo "lua"
        fi
        ;;
    node)
        echo "node"
        ;;
    rust)
        echo "bash" # Rust doesn't have a REPL by default
        ;;
    go)
        echo "bash" # Go doesn't have a built-in REPL
        ;;
    *)
        echo "bash"
        ;;
    esac
}

# Execute development environment command
execute_dev_command() {
    local env="$1"
    local cmd="$2"
    shift 2
    local args=("$@")

    case "$env" in
    nix)
        execute_nix_command "$cmd" "${args[@]}"
        ;;
    python)
        execute_python_command "$cmd" "${args[@]}"
        ;;
    lua)
        execute_lua_command "$cmd" "${args[@]}"
        ;;
    node)
        execute_node_command "$cmd" "${args[@]}"
        ;;
    rust)
        execute_rust_command "$cmd" "${args[@]}"
        ;;
    go)
        execute_go_command "$cmd" "${args[@]}"
        ;;
    *)
        echo "Error: Unknown environment '$env'" >&2
        return 1
        ;;
    esac
}

# Nix environment commands
execute_nix_command() {
    local cmd="$1"
    shift

    case "$cmd" in
    shell)
        if [[ -f "flake.nix" ]]; then
            nix develop --command zsh
        else
            echo "Error: No flake.nix found in current directory" >&2
            return 1
        fi
        ;;
    repl)
        nix repl "$@"
        ;;
    eval)
        nix eval "$@"
        ;;
    run)
        if [[ -f "flake.nix" ]]; then
            nix develop --command "$@"
        else
            nix shell "$@"
        fi
        ;;
    test)
        nix develop --command bash -c "nix flake check"
        ;;
    build)
        nix build "$@"
        ;;
    *)
        echo "Error: Unknown Nix command '$cmd'" >&2
        return 1
        ;;
    esac
}

# Python environment commands
execute_python_command() {
    local cmd="$1"
    shift

    case "$cmd" in
    shell)
        if [[ -f "flake.nix" ]]; then
            nix develop .#python --command zsh
        else
            python3
        fi
        ;;
    repl)
        if command -v ipython >/dev/null; then
            ipython "$@"
        else
            python3 -i "$@"
        fi
        ;;
    eval)
        python3 -c "$@"
        ;;
    run)
        python3 "$@"
        ;;
    test)
        if [[ -f "pyproject.toml" ]]; then
            if command -v pytest >/dev/null; then
                pytest "$@"
            elif command -v python -m pytest >/dev/null; then
                python -m pytest "$@"
            else
                python -m unittest discover "$@"
            fi
        else
            python -m unittest "$@"
        fi
        ;;
    build)
        if [[ -f "pyproject.toml" ]]; then
            python -m build "$@"
        elif [[ -f "setup.py" ]]; then
            python setup.py build "$@"
        else
            echo "No build configuration found (pyproject.toml or setup.py)" >&2
            return 1
        fi
        ;;
    *)
        echo "Error: Unknown Python command '$cmd'" >&2
        return 1
        ;;
    esac
}

# Lua environment commands
execute_lua_command() {
    local cmd="$1"
    shift

    # Determine lua interpreter
    local lua_cmd
    if [[ -f ".luajitrc" || -f "luajit.conf" ]]; then
        lua_cmd="luajit"
    else
        lua_cmd="lua"
    fi

    case "$cmd" in
    shell)
        if [[ -f "flake.nix" ]]; then
            nix develop .#lua --command zsh
        else
            $lua_cmd
        fi
        ;;
    repl)
        $lua_cmd -i "$@"
        ;;
    eval)
        $lua_cmd -e "$@"
        ;;
    run)
        $lua_cmd "$@"
        ;;
    test)
        if command -v busted >/dev/null; then
            busted "$@"
        else
            echo "busted not found. Install with: luarocks install busted" >&2
            return 1
        fi
        ;;
    build)
        if [[ -f "*.rockspec" ]]; then
            luarocks make "$@"
        else
            echo "No rockspec file found" >&2
            return 1
        fi
        ;;
    *)
        echo "Error: Unknown Lua command '$cmd'" >&2
        return 1
        ;;
    esac
}

# Node.js environment commands
execute_node_command() {
    local cmd="$1"
    shift

    case "$cmd" in
    shell)
        if [[ -f "flake.nix" ]]; then
            nix develop .#node --command zsh
        else
            node
        fi
        ;;
    repl)
        node "$@"
        ;;
    eval)
        node -e "$@"
        ;;
    run)
        if [[ -f "package.json" ]] && [[ $# -gt 0 ]] && jq -e ".scripts[\"$1\"]" package.json >/dev/null 2>&1; then
            npm run "$@"
        else
            node "$@"
        fi
        ;;
    test)
        if [[ -f "package.json" ]]; then
            npm test "$@"
        else
            echo "No package.json found" >&2
            return 1
        fi
        ;;
    build)
        if [[ -f "package.json" ]]; then
            npm run build "$@"
        else
            echo "No package.json found" >&2
            return 1
        fi
        ;;
    *)
        echo "Error: Unknown Node command '$cmd'" >&2
        return 1
        ;;
    esac
}

# Rust environment commands
execute_rust_command() {
    local cmd="$1"
    shift

    case "$cmd" in
    shell)
        if [[ -f "flake.nix" ]]; then
            nix develop .#rust --command zsh
        else
            bash
        fi
        ;;
    repl)
        if command -v evcxr >/dev/null; then
            evcxr "$@"
        else
            echo "No Rust REPL available. Install evcxr: cargo install evcxr_repl" >&2
            return 1
        fi
        ;;
    eval)
        echo "Rust eval not supported. Use 'repl' for interactive evaluation" >&2
        return 1
        ;;
    run)
        if [[ -f "Cargo.toml" ]]; then
            cargo run "$@"
        else
            echo "No Cargo.toml found" >&2
            return 1
        fi
        ;;
    test)
        if [[ -f "Cargo.toml" ]]; then
            cargo test "$@"
        else
            echo "No Cargo.toml found" >&2
            return 1
        fi
        ;;
    build)
        if [[ -f "Cargo.toml" ]]; then
            cargo build "$@"
        else
            echo "No Cargo.toml found" >&2
            return 1
        fi
        ;;
    *)
        echo "Error: Unknown Rust command '$cmd'" >&2
        return 1
        ;;
    esac
}

# Go environment commands
execute_go_command() {
    local cmd="$1"
    shift

    case "$cmd" in
    shell)
        if [[ -f "flake.nix" ]]; then
            nix develop .#go --command zsh
        else
            bash
        fi
        ;;
    repl)
        if command -v gore >/dev/null; then
            gore "$@"
        else
            echo "No Go REPL available. Install gore: go install github.com/x-motemen/gore/cmd/gore@latest" >&2
            return 1
        fi
        ;;
    eval)
        echo "Go eval not directly supported. Use 'go run' with a temporary file" >&2
        return 1
        ;;
    run)
        if [[ -f "go.mod" ]]; then
            go run "$@"
        else
            echo "No go.mod found" >&2
            return 1
        fi
        ;;
    test)
        if [[ -f "go.mod" ]]; then
            go test "$@"
        else
            echo "No go.mod found" >&2
            return 1
        fi
        ;;
    build)
        if [[ -f "go.mod" ]]; then
            go build "$@"
        else
            echo "No go.mod found" >&2
            return 1
        fi
        ;;
    *)
        echo "Error: Unknown Go command '$cmd'" >&2
        return 1
        ;;
    esac
}

# Main function
main() {
    local environment=""
    local command="shell"
    local args=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -h | --help)
            show_usage
            exit 0
            ;;
        --list)
            list_environments
            exit 0
            ;;
        --detect)
            local detected
            mapfile -t detected < <(detect_project_type)
            if [[ ${#detected[@]} -gt 0 ]]; then
                echo "Detected project types:"
                printf '  %s\n' "${detected[@]}"
            else
                echo "No specific project type detected"
            fi
            exit 0
            ;;
        nix | python | lua | node | rust | go)
            environment="$1"
            shift
            ;;
        auto)
            local detected
            mapfile -t detected < <(detect_project_type)
            if [[ ${#detected[@]} -gt 0 ]]; then
                environment="${detected[0]}" # Use first detected type
                echo "Auto-detected environment: $environment"
            else
                environment="nix" # Default fallback
                echo "No project type detected, using default: nix"
            fi
            shift
            ;;
        shell | repl | eval | run | test | build)
            command="$1"
            shift
            ;;
        -*)
            echo "Error: Unknown option '$1'" >&2
            show_usage >&2
            exit 1
            ;;
        *)
            args+=("$1")
            shift
            ;;
        esac
    done

    # Auto-detect if no environment specified
    if [[ -z $environment ]]; then
        local detected
        mapfile -t detected < <(detect_project_type)
        if [[ ${#detected[@]} -gt 0 ]]; then
            environment="${detected[0]}"
            echo "Auto-detected environment: $environment"
        else
            environment="nix"
            echo "No project type detected, using default: nix"
        fi
    fi

    # Execute the command
    execute_dev_command "$environment" "$command" "${args[@]}"
}

# Run main function with all arguments
main "$@"
