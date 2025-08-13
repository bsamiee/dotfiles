#!/usr/bin/env bash
# Title         : container-helpers.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : lib/container-helpers.sh
# ---------------------------------------
# Container management helpers for Docker, Compose, and Colima workflows

set -euo pipefail

# --- Docker Container Helpers --------------------------------------------

# Smart shell selection for container exec
container_exec_smart() {
    local container="$1"
    shift
    docker exec -it "$container" sh -c 'bash || zsh || sh' "$@"
}

# Enhanced container logs with timestamps and tail
container_logs_enhanced() {
    local container="$1"
    local lines="${2:-50}"
    docker logs -f --tail="$lines" --timestamps "$container"
}

# Smart container inspection (extract key info)
container_inspect_smart() {
    local container="$1"
    docker inspect "$container" | jq '.[0] | {State, Config: {Image, Cmd, Env}}'
}

# Stop containers with smart defaults (all if none specified)
container_stop_smart() {
    if [[ $# -eq 0 ]]; then
        docker stop "$(docker ps -q)" 2>/dev/null || echo "No running containers to stop"
    else
        docker stop "$@"
    fi
}

# Remove containers with smart defaults (all exited if none specified)
container_remove_smart() {
    if [[ $# -eq 0 ]]; then
        docker rm "$(docker ps -aq -f status=exited)" 2>/dev/null || echo "No stopped containers to remove"
    else
        docker rm "$@"
    fi
}

# Remove images with smart defaults (dangling if none specified)
container_remove_images() {
    if [[ $# -eq 0 ]]; then
        docker rmi "$(docker images -q -f dangling=true)" 2>/dev/null || echo "No dangling images to remove"
    else
        docker rmi "$@"
    fi
}

# Instant development environment
container_dev_env() {
    local image="${1:-node:alpine}"
    shift
    docker run --rm -it -v "$(pwd):/workspace" -w /workspace "$image" "$@"
}

# Container debugging with ptrace
container_debug() {
    local container="$1"
    docker run --rm -it --pid="container:$container" --cap-add SYS_PTRACE alpine sh
}

# Trace container events and logs
container_trace() {
    local container="$1"
    {
        docker events --filter "container=$container" &
        local events_pid=$!
        docker logs -f "$container"
        kill $events_pid 2>/dev/null
    }
}

# Smart cached build with buildx
container_build_cached() {
    local tag="${1:-app}"
    local cache_dir="/tmp/.buildx-cache"
    docker buildx build \
        --cache-from type=local,src="$cache_dir" \
        --cache-to type=local,dest="$cache_dir",mode=max \
        -t "$tag" .
}

# Container system health report
container_health_report() {
    echo "=== Docker System Usage ==="
    docker system df
    echo
    echo "=== Exited Containers ==="
    docker ps -a --filter 'status=exited' | head -20
    echo
    echo "=== Resource Usage ==="
    docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemPerc}}' 2>/dev/null | head -10
}

# Safe container cleanup (only removes unused resources)
container_cleanup_safe() {
    echo "Cleaning up containers..."
    docker container prune -f
    echo "Cleaning up images..."
    docker image prune -f
    echo "Cleaning up build cache..."
    docker builder prune -f
    echo "Cleanup complete!"
}

# --- Docker Compose Helpers ----------------------------------------------

# Compose up with logs
compose_up_with_logs() {
    local tail_lines="${1:-10}"
    docker compose up -d && docker compose logs -f --tail="$tail_lines"
}

# Compose restart with logs
compose_restart_with_logs() {
    local service="$1"
    local tail_lines="${2:-20}"
    docker compose restart "$service" && docker compose logs -f --tail="$tail_lines" "$service"
}

# Compose full cycle (down, up, logs)
compose_cycle() {
    local tail_lines="${1:-20}"
    docker compose down && docker compose up -d && docker compose logs -f --tail="$tail_lines"
}

# Compose rebuild from scratch
compose_rebuild_fresh() {
    docker compose build --no-cache && docker compose up -d --force-recreate
}

# Smart compose exec
compose_exec_smart() {
    local service="$1"
    shift
    docker compose exec "$service" sh -c 'bash || zsh || sh' "$@"
}

# Compose test with cleanup
compose_test_clean() {
    docker compose run --rm test "$@" && docker compose down
}

# Compose environment launcher
compose_env() {
    local env="$1"
    shift
    case "$env" in
    staging)
        docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d "$@"
        ;;
    prod | production)
        docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d "$@"
        ;;
    dev | development)
        docker compose up -d "$@"
        ;;
    *)
        echo "Usage: compose_env {dev|staging|prod} [services...]" >&2
        return 1
        ;;
    esac
}

# Compose service monitoring
compose_watch() {
    watch -n 2 'docker compose ps && echo && docker compose top'
}

# Enhanced compose logs
compose_logs_enhanced() {
    local lines="${1:-50}"
    shift
    docker compose logs -f --tail="$lines" --timestamps "$@"
}

# --- Colima Helpers -----------------------------------------------------

# Smart Colima start with profile support
colima_start_smart() {
    local profile_or_cpu="$1"
    local cpu=4
    local memory=8
    local disk=100

    if [[ -n $profile_or_cpu && $profile_or_cpu =~ ^[0-9]+$ ]]; then
        # Numeric argument = CPU count
        cpu="$profile_or_cpu"
    elif [[ -n $profile_or_cpu ]]; then
        # String argument = profile name
        colima start --profile "$profile_or_cpu" --cpu "$cpu" --memory "$memory" --disk "$disk"
        return
    fi

    colima start --cpu "$cpu" --memory "$memory" --disk "$disk"
}

# Comprehensive Colima status
colima_status_full() {
    echo "=== Colima Status ==="
    colima status
    echo
    echo "=== Available Profiles ==="
    colima list
}

# Colima profile switcher
colima_switch_profile() {
    local profile="$1"
    if [[ -z $profile ]]; then
        echo "Usage: colima_switch_profile <profile_name>" >&2
        return 1
    fi
    colima stop && colima start --profile "$profile"
}

# Specialized Colima profiles
colima_profile_m1() {
    colima start --arch aarch64 --vm-type=vz --vz-rosetta --cpu 4 --memory 8
}

colima_profile_k8s() {
    colima start --profile k8s --kubernetes --cpu 6 --memory 12
}

colima_profile_test() {
    colima start --profile test --cpu 2 --memory 4
}

# Colima restart
colima_restart() {
    colima stop && colima start
}

# --- Unified Container Functions ----------------------------------------

# Get container runtime status (Docker or Colima)
container_runtime_status() {
    echo "=== Container Runtime Status ==="

    # Check Docker daemon
    if docker info >/dev/null 2>&1; then
        echo "✓ Docker daemon: Running"
        docker version --format 'Client: {{.Client.Version}}, Server: {{.Server.Version}}'
    else
        echo "✗ Docker daemon: Not running"
    fi

    echo

    # Check Colima if available
    if command -v colima >/dev/null 2>&1; then
        echo "=== Colima Status ==="
        colima_status_full
    else
        echo "Colima: Not installed"
    fi
}

# Universal container cleanup
container_cleanup_full() {
    echo "=== Full Container Cleanup ==="
    echo "This will remove all stopped containers, unused images, networks, and volumes."
    read -p "Continue? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker system prune -af --volumes
        docker builder prune -af
        echo "Full cleanup complete!"
    else
        echo "Cleanup cancelled."
    fi
}

# Container development workflow
container_dev_workflow() {
    local action="$1"
    shift

    case "$action" in
    start)
        echo "Starting development environment..."
        compose_up_with_logs 20
        ;;
    restart)
        echo "Restarting services..."
        compose_cycle 20
        ;;
    rebuild)
        echo "Rebuilding from scratch..."
        compose_rebuild_fresh
        ;;
    test)
        echo "Running tests..."
        compose_test_clean "$@"
        ;;
    logs)
        echo "Following logs..."
        compose_logs_enhanced 50 "$@"
        ;;
    shell)
        local service="${1:-app}"
        echo "Opening shell in $service..."
        compose_exec_smart "$service"
        ;;
    status)
        echo "Container status..."
        container_health_report
        ;;
    clean)
        echo "Cleaning up..."
        container_cleanup_safe
        ;;
    *)
        echo "Usage: container_dev_workflow {start|restart|rebuild|test|logs|shell|status|clean} [options...]" >&2
        return 1
        ;;
    esac
}
