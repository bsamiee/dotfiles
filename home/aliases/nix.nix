# Title         : nix.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/shells/aliases/nix.nix
# ---------------------------------------
# Nix ecosystem aliases - unified mega namespace for all nix-related tools
{ lib, ... }:

let
  # --- Nix Commands (dynamically prefixed with 'n') -----------------------------
  nixCommands = {
    # Core development (single letter - highest frequency)
    b = "nom build"; # nb
    d = "nom develop"; # nd
    r = "nix run"; # nr

    # Package/profile management (two letters)
    pi = "nix profile install"; # npi
    pr = "nix profile remove"; # npr
    pl = "nix profile list"; # npl
    pu = "nix profile upgrade"; # npu
    sh = "nix shell"; # nsh
    prollback = "nix profile rollback"; # nprollback

    # Flake operations (two letters)
    fu = "nix flake update"; # nfu
    fc = "nix-fast-build --skip-cached --flake '.#checks'"; # nfc - fast parallel check
    fs = "nix flake show"; # nfs
    fl = "nix flake lock"; # nfl
    fli = "nix flake lock --update-input"; # nfli
    fm = "nix flake metadata"; # nfm

    # Development environments (two letters/semantic)
    dp = "nix develop .#python"; # ndp
    dd = "nix develop --command"; # ndd
    di = "nix develop --impure"; # ndi
    envrc = "echo 'use flake' > .envrc && direnv allow"; # nenvrc

    # Darwin operations (scripts now in PATH via modules/scripts.nix)
    rb = "rebuild"; # nrb - smart rebuild
    rc = "rebuild -c"; # nrc - rebuild with fast check
    ru = "rebuild -u"; # nru - rebuild with update
    rp = "rebuild -p"; # nrp - rebuild with preview (no switch)
    rd = "rebuild -d"; # nrd - rebuild with diff
    drrollback = "darwin-rebuild switch --rollback"; # ndrrollback - emergency rollback

    # Home-manager operations (two letters/semantic)
    hmb = "home-manager build --flake ."; # nhmb
    hms = "home-manager switch --flake ."; # nhms
    hmg = "home-manager generations"; # nhmg
    hmp = "home-manager packages"; # nhmp
    hmn = "home-manager news"; # nhmn
    hme = "home-manager edit"; # nhme
    hmrollback = "home-manager switch --rollback"; # nhmrollback
    hmexpire = "home-manager expire-generations '-30 days'"; # nhmexpire

    # Build variants (semantic)
    fb = "nix-fast-build"; # nfb - 90% faster
    fallback = "nix build --fallback"; # nfallback
    offline = "nix build --offline"; # noffline
    debug = "nix build --log-format internal-json -v --print-build-logs --keep-failed |& nom --json"; # ndebug - verbose build with logs

    # Store inspection (semantic)
    du = "nix-du"; # ndu - disk usage (devshell)
    tree = "nix-tree"; # ntree - dependency tree (devshell)
    why = "nix-store --query --roots"; # nwhy
    size = "nix path-info --closure-size -h"; # nsize
    find = "nix-locate --whole-name"; # nfind
    index = "nix-index"; # nindex

    # Diagnostics & debugging (semantic)
    diff = "nix-diff"; # ndiff - compare derivations (devshell)
    log = "nix log"; # nlog
    repl = "nix repl"; # nrepl
    eval = "nix eval"; # neval
    show = "nix show-derivation"; # nshow
    health = "nix-health"; # nhealth - store health check

    # Visualization & comparison (available in devshell via 'nd')
    vdiff = "nvd"; # nvdiff - compare generations (devshell)
    viz = "f() { format=\${2:-png}; nix-visualize \"\$1\" -o \"\${3:-graph.\$format}\"; }; f"; # nviz - create dependency graph (usage: nviz derivation [format] [output])

    # Code quality & formatting (unified semantics)
    fmt = "f() { nixfmt \"\${@:-.}\"; }; f"; # fmt - format files (consolidated)
    lint = "f() { deadnix --hidden --no-underscore --fail \"\${@:-.}\" && statix check \"\${@:-.}\"; }; f"; # lint - comprehensive check (unified semantic)
    lintf = "f() { deadnix --hidden --no-underscore --edit \"\${@:-.}\" && statix fix \"\${@:-.}\"; }; f"; # lintf - comprehensive auto-fix (unified semantic)
    dead = "f() { deadnix --hidden --no-underscore \"\${@:-.}\"; }; f"; # ndead - find dead code only
    deadf = "f() { deadnix --hidden --no-underscore --edit \"\${@:-.}\"; }; f"; # ndeadf - fix dead code only
    report = "f() { qa-report.sh nix \"\${@:-.}\"; }; f"; # nreport - comprehensive report

    # Deployment & remote (semantic)
    deploy = "deploy-darwin"; # ndeploy [server] [action] - smart deployment

    # Generation management
    gens = "darwin-rebuild --list-generations"; # ngens - list all generations
    gendiff = "f() { source ${"DOTFILES:-$HOME/.dotfiles"}/lib/common.sh; generation_diff \"\$@\"; }; f"; # ngendiff [gen1] [gen2] - compare generations
    genswitch = "f() { darwin-rebuild switch --switch-generation \"\$1\" --flake .; }; f"; # ngenswitch <num> - switch to generation
    preview = "preview"; # npreview - preview changes (script in PATH)

    # Garbage collection & cleanup
    gc = "nix-collect-garbage -d"; # ngc - delete old generations
    gcold = "nix-collect-garbage --delete-older-than 30d"; # ngcold - delete 30+ day old
    gcinfo = "echo 'Store usage:' && df -h /nix/store && echo 'GC roots:' && nix-store --gc --print-roots | wc -l && echo 'Dead paths:' && nix-store --gc --print-dead 2>/dev/null | wc -l"; # ngcinfo - store status

    # Store verification & repair
    verify = "nix-store --verify --check-contents"; # nverify - verify store integrity
    repair = "nix-store --verify --check-contents --repair"; # nrepair - repair corrupted paths

    # Cache management (setup and warming)
    cache = "cachix-manager"; # ncache - cache management
    csetup = "$DOTFILES/scripts/cachix.sh setup"; # ncsetup - setup cachix
    cstatus = "$DOTFILES/scripts/cachix.sh status"; # ncstatus - cache status
    warm = "$DOTFILES/scripts/cachix.sh warm"; # nwarm [inputs|dev|darwin|packages|all] - warm cache
  };
in
{
  aliases = lib.mapAttrs' (name: value: {
    # Export aliases with 'n' prefix
    name = "n${name}";
    inherit value;
  }) nixCommands;
}
