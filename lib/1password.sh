#!/usr/bin/env bash
# Title         : 1password.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : lib/1password.sh
# ---------------------------------------
# 1Password CLI helper functions for unified secrets management

# --- 1Password Availability Functions -----------------------------------------
op_available() {
    command -v op &>/dev/null
}

op_authenticated() {
    op_available && op account get &>/dev/null
}

op_signin_if_needed() {
    if ! op_authenticated; then
        echo "Signing into 1Password..."
        op signin --raw && return 0
        return 1
    fi
    return 0
}

# --- Secret Retrieval Functions -----------------------------------------------
op_get_secret() {
    local item="$1"
    local vault="${2:-Private}"
    local field="${3:-credential}"

    if ! op_available; then
        return 1
    fi

    if ! op_signin_if_needed; then
        return 1
    fi

    # Use secret reference format for consistency
    local reference="op://$vault/$item/$field"

    # Try to read the secret
    op read "$reference" 2>/dev/null
}

op_set_secret() {
    local title="$1"
    local name="$2" # Used for reference
    local value="$3"
    local vault="${4:-Private}"

    if ! op_available; then
        return 1
    fi

    if ! op_signin_if_needed; then
        return 1
    fi

    # Check if item already exists
    if op item get "$name" --vault="$vault" &>/dev/null; then
        # Update existing item
        echo "$value" | op item edit "$name" --vault="$vault" 'credential[password]'=-
    else
        # Create new item
        op item create \
            --category="password" \
            --title="$title" \
            --vault="$vault" \
            'credential[password]'="$value" \
            --tags="dotfiles,automated"
    fi
}

op_generate_ssh_key() {
    local name="${1:-dev-key}"
    local vault="${2:-Private}"
    local title="SSH Key - $name"

    if ! op_available; then
        return 1
    fi

    if ! op_signin_if_needed; then
        return 1
    fi

    # Generate SSH key in 1Password
    op item create \
        --category="ssh-key" \
        --title="$title" \
        --vault="$vault" \
        --ssh-generate-key \
        --tags="dotfiles,ssh,automated"
}

# --- Environment Injection Functions ------------------------------------------
op_run_with_env() {
    local env_file="$1"
    shift

    if ! op_available; then
        return 1
    fi

    if ! op_signin_if_needed; then
        return 1
    fi

    # Use op run to inject secrets from env file
    op run --env-file="$env_file" -- "$@"
}

op_inject_template() {
    local template_file="$1"
    local output_file="$2"

    if ! op_available; then
        return 1
    fi

    if ! op_signin_if_needed; then
        return 1
    fi

    op inject -i "$template_file" -o "$output_file"
}

# --- SSH Integration Functions ------------------------------------------------
op_get_ssh_public_key() {
    local key_name="$1"
    local vault="${2:-Private}"

    if ! op_available; then
        return 1
    fi

    if ! op_signin_if_needed; then
        return 1
    fi

    # Get the public key from the SSH key item
    op item get "$key_name" --vault="$vault" --fields="public key" 2>/dev/null
}

op_list_ssh_keys() {
    local vault="${1:-Private}"

    if ! op_available; then
        return 1
    fi

    if ! op_signin_if_needed; then
        return 1
    fi

    # List all SSH key items
    op item list --categories="SSH Key" --vault="$vault" --format=json 2>/dev/null |
        jq -r '.[].title' 2>/dev/null || echo "No SSH keys found"
}

# --- Utility Functions --------------------------------------------------------
op_create_env_template() {
    local output_file="${1:-secrets.env.template}"

    cat >"$output_file" <<EOF
# 1Password Secret References Template
# Use with: secrets-manager env secrets.env <command>

# Common secrets
CACHIX_AUTH_TOKEN=op://Private/cachix-auth-token/credential
GITHUB_TOKEN=op://Private/github-token/credential

# API Keys (customize as needed)
# OPENAI_API_KEY=op://Private/openai-api-key/credential
# ANTHROPIC_API_KEY=op://Private/anthropic-api-key/credential

# Database/Service URLs
# DATABASE_URL=op://Private/database/url
# REDIS_URL=op://Private/redis/url
EOF

    echo "Template created: $output_file"
}

op_health_check() {
    local vault="${1:-Private}"

    echo "1Password Health Check:"
    echo ""

    if ! op_available; then
        echo "❌ 1Password CLI not installed"
        return 1
    fi

    echo "✅ 1Password CLI available"

    if ! op_authenticated; then
        echo "❌ Not authenticated (run 'op signin')"
        return 1
    fi

    echo "✅ Authenticated"

    # Test reading a common secret
    if op_get_secret "cachix-auth-token" "$vault" >/dev/null 2>&1; then
        echo "✅ Can read secrets from vault: $vault"
    else
        echo "⚠️  Cannot read cachix-auth-token (may not exist)"
    fi

    # Check SSH keys
    local ssh_count
    ssh_count=$(op item list --categories="SSH Key" --vault="$vault" --format=json 2>/dev/null | jq length 2>/dev/null || echo 0)
    echo "📋 SSH keys in vault: $ssh_count"

    echo ""
    echo "✅ 1Password health check complete"
}

# --- Integration Helpers ------------------------------------------------------
# Get the appropriate 1Password socket path for SSH agent
get_1password_socket_path() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else
        echo "$HOME/.1password/agent.sock"
    fi
}

# Check if 1Password SSH agent is available
op_ssh_agent_available() {
    local socket_path
    socket_path=$(get_1password_socket_path)

    [[ -S $socket_path ]] && SSH_AUTH_SOCK="$socket_path" ssh-add -l &>/dev/null 2>&1
}
