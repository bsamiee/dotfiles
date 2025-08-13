# Title         : devops.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/shells/aliases/devops.nix
# ---------------------------------------
# DevOps aliases - Docker, Colima, Kubernetes, and container orchestration
{ lib, ... }:

let
  # --- Docker Commands (dynamically prefixed with 'd') -------------------------
  dockerCommands = {
    # Container management (single/two letters - high frequency)
    ps = "ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}'"; # dps - smart format all containers
    i = "images"; # di - list images
    r = "run --rm -it"; # dr - run interactive, remove after
    e = "f() { docker exec -it \$1 sh -c 'bash || zsh || sh'; }; f"; # de - smart shell selection

    # Container operations (consolidated management function)
    manage = "!f() { action=\${1:-status}; shift; case \$action in status) docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}' ;; stop) docker stop \${@:-\$(docker ps -q)} ;; rm) docker rm \${@:-\$(docker ps -aq -f status=exited)} ;; rmi) docker rmi \${@:-\$(docker images -q -f dangling=true)} ;; clean) docker container prune -f && docker image prune -f ;; *) echo 'Usage: dmanage [status|stop|rm|rmi|clean] [args]' ;; esac; }; f"; # dmanage - unified container management

    # Logs and inspection (enhanced)
    l = "f() { docker logs -f --tail=50 --timestamps \${@}; }; f"; # dl - follow logs with timestamps
    inspect = "f() { docker inspect \$1 | jq '.[0] | {State, Config: {Image, Cmd, Env}}'; }; f"; # dinspect - smart inspect
    stats = "stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemPerc}}'"; # dstats - resource usage

    # Development workflows (consolidated operations)
    dev = "f() { docker run --rm -it -v \$(pwd):/workspace -w /workspace \${1:-node:alpine} \${@:2}; }; f"; # ddev - instant dev env
    debug = "f() { docker run --rm -it --pid=container:\$1 --cap-add SYS_PTRACE alpine sh; }; f"; # ddebug - attach debugger
    trace = "f() { docker events --filter container=\$1 & docker logs -f \$1; }; f"; # dtrace - trace container

    # Build operations (intelligent caching)
    b = "build -t"; # db - build with tag
    build = "f() { docker buildx build --cache-from type=local,src=/tmp/.buildx-cache --cache-to type=local,dest=/tmp/.buildx-cache,mode=max -t \${1:-app} .; }; f"; # dbuild - smart cached build

    # Dockerfile linting with hadolint
    lint = "f() { hadolint --format tty \${@:-Dockerfile*} 2>/dev/null || hadolint \${@:-Dockerfile}; }; f"; # dlint - lint Dockerfiles (tries glob first, then default)

    # Code quality & diagnostics (unified semantics)
    qa = "f() { docker system df && echo && docker ps -a --filter 'status=exited' | head -20; }; f"; # dqa - health check
    qaf = "f() { docker container prune -f && docker image prune -f && docker builder prune -f; }; f"; # dqaf - safe cleanup
    report = "qa-report.sh docker"; # dreport - full report

    # Cleanup operations (full words for clarity)
    prune = "system prune -f"; # dprune - basic cleanup
    clean = "system prune -af --volumes && docker builder prune -af"; # dclean - total cleanup

    # Volume operations
    v = "volume ls"; # dv - list volumes
    vprune = "volume prune -f"; # dvprune - remove unused volumes

    # Network operations
    n = "network ls"; # dn - list networks
    nprune = "network prune -f"; # dnprune - remove unused networks
  };

  # --- Docker Compose Commands (prefixed with 'dc') ----------------------------
  composeCommands = {
    # Core operations (high frequency)
    up = "f() { docker compose up -d && docker compose logs -f --tail=10; }; f"; # dcup - start+follow logs
    down = "down"; # dcdown - stop and remove
    ps = "ps"; # dcps - list services

    # Smart workflows (consolidated operations)
    restart = "f() { docker compose restart \${1} && docker compose logs -f --tail=20 \${1}; }; f"; # dcrestart - restart+logs
    cycle = "f() { docker compose down && docker compose up -d && docker compose logs -f --tail=20; }; f"; # dccycle - full cycle
    rebuild = "f() { docker compose build --no-cache && docker compose up -d --force-recreate; }; f"; # dcrebuild - fresh rebuild

    # Development operations
    exec = "f() { docker compose exec \$1 sh -c 'bash || zsh || sh'; }; f"; # dcexec - smart shell
    test = "f() { docker compose run --rm test \${@} && docker compose down; }; f"; # dctest - run tests and cleanup
    watch = "f() { watch -n 2 'docker compose ps && echo && docker compose top'; }; f"; # dcwatch - monitor services

    # Environment management
    stage = "f() { docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d; }; f"; # dcstage - staging env
    prod = "f() { docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d; }; f"; # dcprod - production env

    # Maintenance
    logs = "f() { docker compose logs -f --tail=50 --timestamps \${@}; }; f"; # dclogs - follow logs with timestamps
    pull = "pull"; # dcpull - pull images
    build = "build"; # dcbuild - build services
  };

  # --- Colima Commands (prefixed with 'col') -----------------------------------
  colimaCommands = {
    # Core operations
    start = "f() { colima start \${1:+--profile \$1} --cpu 4 --memory 8 --disk 100; }; f"; # colstart [profile] - smart profile start
    stop = "stop"; # colstop - stop VM
    status = "f() { colima status && echo && colima list; }; f"; # colstatus - comprehensive status
    ssh = "ssh"; # colssh - SSH into VM

    # Profile management (workflows)
    profile = "f() { colima start --profile \${1:-default} --cpu 4 --memory 8; }; f"; # colprofile - manage profiles
    switch = "f() { colima stop && colima start --profile \$1; }; f"; # colswitch profile - switch profiles

    # Specialized profiles
    m1 = "start --arch aarch64 --vm-type=vz --vz-rosetta --cpu 4 --memory 8"; # colm1 - optimized for Apple Silicon
    k8s = "start --profile k8s --kubernetes --cpu 6 --memory 12"; # colk8s - kubernetes profile
    test = "start --profile test --cpu 2 --memory 4"; # coltest - minimal test profile

    # Maintenance
    clean = "delete --force"; # colclean - remove VM
    restart = "f() { colima stop && colima start; }; f"; # colrestart - restart VM
  };

  # --- Kubernetes Commands (prefixed with 'k' - if enabled) --------------------
  # These are commented out but ready when kubernetes is enabled
in
{
  aliases =
    # Docker aliases with 'd' prefix
    lib.mapAttrs' (name: value: {
      name = "d${name}";
      value =
        if lib.hasPrefix "f()" value then
          value # Function definitions pass through
        else
          "docker ${value}";
    }) dockerCommands
    # Docker Compose aliases with 'dc' prefix
    // lib.mapAttrs' (name: value: {
      name = "dc${name}";
      value = "docker compose ${value}";
    }) composeCommands
    # Colima aliases with 'col' prefix
    // lib.mapAttrs' (name: value: {
      name = "col${name}";
      value = "colima ${value}";
    }) colimaCommands

    # Kubernetes would go here when enabled
    # // lib.mapAttrs' (name: value: {
    #   name = "k${name}";
    #   value = "kubectl ${value}";
    # }) kubernetesCommands

    // {
      # Standalone shortcuts
      d = "docker"; # Base docker command
      dc = "docker compose"; # Base compose command
      col = "colima"; # Base colima command
      # k = "kubectl"; # Base kubectl (when enabled)

      # Container workflow helpers (using lib/container-helpers.sh)
      cstatus = ". ~/.dotfiles/lib/container-helpers.sh && container_runtime_status"; # Container runtime status
      cdev = ". ~/.dotfiles/lib/container-helpers.sh && container_dev_workflow"; # Development workflow helper
      ccleanup = ". ~/.dotfiles/lib/container-helpers.sh && container_cleanup_full"; # Full cleanup with confirmation

      # Docker system info
      dinfo = "docker system df"; # Disk usage info
      dversion = "docker version --format 'Client: {{.Client.Version}}\nServer: {{.Server.Version}}'"; # Version info
    };
}
