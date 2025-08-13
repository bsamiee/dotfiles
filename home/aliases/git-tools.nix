# Title         : git-tools.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/shells/aliases/git-tools.nix
# ---------------------------------------
# Git version control aliases - dynamically generated for consistency
{ lib, ... }:

let
  # --- Core Git Commands (dynamically prefixed with 'g') ------------------------
  gitCommands = {
    # Status & inspection (single/two letters - highest frequency)
    s = "status -sb"; # gs - short status with branch
    # Consolidated log function with parameters
    l = "!f() { case \${1:-short} in short) git log --oneline --graph --decorate -10 ;; full) git log --oneline --graph --decorate ;; pretty) git log --pretty=format:'%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) [%an]' --abbrev-commit -20 ;; graph) git log --graph --pretty=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --abbrev-commit --all ;; [0-9]*) git log --oneline --graph --decorate -\$1 ;; *) echo 'Usage: gl [short|full|pretty|graph|NUMBER]' ;; esac; }; f"; # gl - smart log function
    d = "diff"; # gd - working changes
    ds = "diff --staged"; # gds - staged changes (cached)
    dc = "diff --cached"; # gdc - alias for staged

    # File operations (two letters - high frequency)
    a = "add"; # ga - stage files
    aa = "add --all"; # gaa - stage everything
    ap = "add --patch"; # gap - stage interactively
    c = "commit"; # gc - commit
    cm = "commit -m"; # gcm - commit with message
    ca = "commit --amend --no-edit"; # gca - amend, keep message
    cae = "commit --amend"; # gcae - amend, edit message

    # Push/pull/fetch (single/two letters - high frequency)
    p = "push"; # gp - push
    pf = "push --force-with-lease"; # gpf - force push safely
    pl = "pull --rebase --autostash"; # gpl - pull with rebase
    f = "fetch --all --prune --prune-tags"; # gf - fetch and clean

    # Branch operations (two/three letters - medium frequency)
    b = "branch -vv"; # gb - branches with tracking
    br = "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate"; # gbr - enhanced branch list
    co = "checkout"; # gco - switch branch
    cb = "checkout -b"; # gcb - create & switch branch
    sw = "switch"; # gsw - modern switch command
    sc = "switch -c"; # gsc - switch create
    m = "merge --no-ff"; # gm - merge with commit
    bd = "branch -d"; # gbd - delete branch (safe)
    bD = "branch -D"; # gbD - force delete branch

    # Rebase operations (semantic)
    rb = "rebase"; # grb - rebase
    rbi = "rebase -i HEAD~10"; # grbi - interactive rebase
    rbc = "rebase --continue"; # grbc - continue rebase
    rba = "rebase --abort"; # grba - abort rebase

    # Stash operations (two/three letters)
    st = "stash push -u"; # gst - stash including untracked
    stp = "stash pop"; # gstp - pop stash
    stl = "stash list"; # gstl - list stashes
    sta = "stash apply"; # gsta - apply stash
    std = "stash drop"; # gstd - drop stash
    sts = "stash show -p"; # gsts - show stash diff

    # Remote operations (semantic)
    r = "remote -v"; # gr - list remotes
    ra = "remote add"; # gra - add remote
    rr = "remote remove"; # grr - remove remote

    # Reset operations (semantic - dangerous)
    rs = "reset"; # grs - reset
    rsh = "reset --hard"; # grsh - hard reset

    # Cherry-pick & advanced (semantic)
    cp = "cherry-pick"; # gcp - cherry-pick
    cpa = "cherry-pick --abort"; # gcpa - abort cherry-pick
    cpc = "cherry-pick --continue"; # gcpc - continue cherry-pick

    # Inspection & analysis (semantic)
    who = "shortlog -sn"; # gwho - contributor stats
    contrib = "contrib"; # gcontrib - detailed per-user contributions (git-extras)

    # Workflow operations (semantic - clear intent)
    wip = "!git add -A && git commit -m 'wip' --no-verify"; # gwip - work in progress
    undo = "undo"; # gundo - safe undo with prompts (git-extras)
    unstage = "reset HEAD --"; # gunstage - unstage files
    uncommit = "reset --soft HEAD~1"; # guncommit - uncommit, keep staged
    fixup = "!f() { git commit --fixup=$1; }; f"; # gfixup - fixup commit
    squash = "!f() { git rebase -i --autosquash $1~; }; f"; # gsquash - squash commits

    # Maintenance (full words - administrative clarity)
    cleanup = "!git remote prune origin && git gc --auto"; # gcleanup - clean remotes & gc
    prune = "remote prune origin"; # gprune - prune remote branches
    gc = "gc --aggressive --prune=now"; # ggc - aggressive garbage collect
    verify = "fsck --full"; # gverify - verify repo integrity

    # Dangerous operations (full words for safety)
    nuke = "!git reset --hard HEAD && git clean -fd"; # gnuke - discard everything
    pristine = "!git reset --hard && git clean -fdx"; # gpristine - total reset

    # Git-extras workflow tools (semantic)
    ignore = "ignore"; # gignore - add to .gitignore
    summary = "summary"; # gsummary - repo statistics
    delmerged = "delete-merged-branches"; # gdelmerged - cleanup merged branches
    standup = "standup"; # gstandup - recent work summary

    # Git-extras analysis & information
    authors = "authors"; # gauthors - generate AUTHORS file
    effort = "effort"; # geffort - show effort statistics per file
    info = "info"; # ginfo - show repository information
    changelog = "changelog"; # gchangelog - generate changelog from commits

    # Git-extras branch & sync operations
    sync = "sync"; # gsync - sync with upstream
    fresh = "fresh-branch"; # gfresh - create fresh branch from default
    showtree = "show-tree"; # gshowtree - show working tree status

    # Git-extras advanced tools
    repl = "repl"; # grepl - interactive git shell
    bulk = "bulk"; # gbulk - manage multiple repositories
    lock = "lock"; # glock - lock files
    unlock = "unlock"; # gunlock - unlock files
  };

  # --- Git LFS Commands (only the frequently used ones) -------------------------
  lfsCommands = {
    t = "lfs track"; # glfst - track file pattern
    ls = "lfs ls-files"; # glfsls - list tracked files
    s = "lfs status"; # glfss - LFS-specific status
  };

  # --- GitHub CLI Commands (dynamically prefixed with 'gh') ---------------------
  ghCommands = {
    # Pull Request workflows (single/two letters - highest frequency)
    co = "pr checkout"; # ghco - checkout PR locally
    pv = "pr view --web"; # ghpv - view PR in browser
    pc = "pr create --web"; # ghpc - create PR in browser
    pm = "pr merge --squash --delete-branch"; # ghpm - merge and cleanup

    # Pull Request listing (semantic)
    pl = "pr list --author @me"; # ghpl - my PRs
    prl = "pr list --reviewer @me"; # ghprl - PRs I'm reviewing
    pra = "pr list --assignee @me"; # ghpra - PRs assigned to me
    ps = "pr status"; # ghps - PR status overview
    pcheck = "pr checks"; # ghpcheck - check status

    # Repository management (single/two letters)
    rv = "repo view --web"; # ghrv - open repo in browser
    rc = "repo clone"; # ghrc - clone repository
    rf = "repo fork"; # ghrf - fork repository

    # Issue management (semantic)
    il = "issue list --assignee @me"; # ghil - my assigned issues
    ic = "issue create --web"; # ghic - create issue in browser
    iv = "issue view --web"; # ghiv - view issue in browser

    # Workflow & CI (semantic)
    wl = "workflow list"; # ghwl - list workflows
    wr = "workflow run"; # ghwr - run workflow
    wv = "workflow view"; # ghwv - view workflow
    runs = "run list --limit 10"; # ghruns - recent workflow runs

    # Advanced operations (semantic)
    bl = "repo view --branch"; # ghbl - view branch info
    rl = "release list --limit 5"; # ghrl - recent releases
    rla = "release view --web"; # ghrla - latest release
    api = "api"; # ghapi - direct API access
    gl = "gist list --limit 10"; # ghgl - recent gists

    # Search and discovery (semantic)
    sr = "search repos"; # ghsr - repository search
    si = "search issues"; # ghsi - issue search
    sp = "search prs"; # ghsp - pull request search
  };
in
{
  aliases =
    # Git commands with 'g' prefix
    lib.mapAttrs' (name: value: {
      name = "g${name}";
      value = "git ${value}";
    }) gitCommands
    # Git LFS commands with 'glfs' prefix
    // lib.mapAttrs' (name: value: {
      name = "glfs${name}";
      value = "git ${value}";
    }) lfsCommands
    # GitHub CLI commands with 'gh' prefix
    // lib.mapAttrs' (name: value: {
      name = "gh${name}";
      value = "gh ${value}";
    }) ghCommands
    // {
      # Special cases that don't follow the pattern
      g = "git"; # Base git command
      gh = "gh"; # Base GitHub CLI command
      lazygit = "lazygit"; # TUI for git (if installed)
      lg = "lazygit"; # Short alias for lazygit
    };
}
