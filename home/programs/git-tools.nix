# Title         : git-tools.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/programs/git-tools.nix
# ---------------------------------------
# Consolidated Git ecosystem tools - Git, GitHub CLI, and Lazygit configuration
# Configuration directory is automatically created by darwin/modules/xdg.nix
# Lazygit settings are written to ${config.xdg.configHome}/lazygit/config.yml

{
  config,
  pkgs,
  lib,
  userConfig,
  myLib,
  ...
}:

{
  # --- Git Core Configuration ---------------------------------------------------
  programs = {
    git = {
      enable = true;
      # --- User Information ---------------------------------------------------------
      userName = userConfig.gitUsername;
      userEmail = userConfig.gitEmail;
      # --- Git Tools ----------------------------------------------------------------
      lfs.enable = true;
      delta = {
        enable = myLib.default true;
        options = {
          navigate = myLib.default true;
          line-numbers = myLib.default true;
        };
      };
      # --- Core Configuration -------------------------------------------------------
      extraConfig = {
        init.defaultBranch = myLib.default "master";
        pull.ff = myLib.default "only";
        # Git extras configuration
        git-extras.default-branch = myLib.default "master";
        # Changelog generation format (git-extras)
        changelog = {
          format = myLib.default "* %s"; # Standard changelog format
          mergeformat = myLib.default "* %s"; # Format for merge commits
        };
        push = {
          default = myLib.default "current";
          autoSetupRemote = myLib.default true;
        };
        core = {
          editor = myLib.default "nvim";
          autocrlf = myLib.default "input";
          whitespace = myLib.default "trailing-space,space-before-tab";
          excludesfile = myLib.default "${config.xdg.configHome}/git/ignore";
          attributesfile = myLib.default "${config.xdg.configHome}/git/attributes";
        };
        diff = {
          colorMoved = myLib.default "default";
          algorithm = myLib.default "histogram";
        };
        merge = {
          conflictstyle = myLib.default "zdiff3";
        };
        rerere = {
          enabled = myLib.default true;
        };
        fetch = {
          prune = myLib.default true;
          prunetags = myLib.default true;
        };
        pack = {
          threads = myLib.default 0;
        };
        # Transfer safety
        transfer = {
          fsckobjects = myLib.default true;
        }; # Verify objects on transfer
        status = {
          branch = myLib.default true;
          showUntrackedFiles = myLib.default "all";
        }; # Better status output
        # Better rebase experience
        rebase = {
          autoStash = myLib.default true;
          autoSquash = myLib.default true;
          updateRefs = myLib.default true;
        };
        # Commit improvements
        commit = {
          verbose = myLib.default true; # Show diff in commit message editor
          gpgsign = myLib.default false; # Disable GPG signing (using SSH signing instead)
        };
        # SSH signing configuration (automatic with 1Password integration)
        gpg = {
          format = myLib.default "ssh"; # Use SSH keys for signing
          ssh.allowedSignersFile = myLib.default "${config.xdg.configHome}/git/allowed_signers";
        };
        branch = {
          sort = myLib.default "-committerdate";
        }; # Sort branches by recency
        # Quality of life improvements
        help = {
          autocorrect = myLib.default 20; # Auto-run mistyped commands after 2 seconds
        };
      };
    };

    # --- GitHub CLI Configuration -------------------------------------------------
    gh = {
      enable = true;

      # --- Git Integration ----------------------------------------------------------
      # Inherit git protocol preference (SSH for security)
      settings.git_protocol = "ssh";

      # --- User Experience ---------------------------------------------------------
      settings = {
        # Editor integration - consistent with git config
        editor = config.programs.git.extraConfig.core.editor or "nvim";
        # Interactive prompts for better UX
        prompt = "enabled";
        # Paging - respect environment variable (empty for scripting)
        pager = "";
        # Browser integration - use system default
        browser = "";

        # --- Accessibility & Display -------------------------------------------------
        # Modern color support for better readability
        accessible_colors = false;
        # Performance - disable spinner in CI (auto-detected)
        spinner = "enabled";

        # --- Advanced Features ------------------------------------------------------
        # Prefer terminal prompts over editor-based ones
        prefer_editor_prompt = "disabled";
      };
    };

    # --- Lazygit Configuration ----------------------------------------------------
    lazygit = {
      enable = true;

      settings = {
        # --- User Interface Optimizations --------------------------------------------
        gui = {
          # Enhanced file tree view for better repository overview
          showFileTree = true;
          # Clean UI - disable command log and bottom line clutter
          showCommandLog = false;
          showBottomLine = false;
          # Modern rounded borders appearance
          border = "rounded";
          # Optimized panel width for productivity
          sidePanelWidth = 0.3333;
          # Nerd Fonts v3 for better icons and symbols
          nerdFontsVersion = "3";
        };

        # --- Git Workflow Integration ------------------------------------------------
        git = {
          # Paging configuration (integrates with system git config)
          paging = {
            colorArg = "always";
            # Use system pager config from git-tools.nix (empty for scripting compatibility)
            pager = "";
          };

          # Commit and merge strategy
          pull.mode = "rebase"; # Consistent with clean git history practices

          # Automatic operations for productivity
          autoRefresh = true;
          autoFetch = true;

          # Main branch detection (covers common naming conventions)
          mainBranches = [
            "master"
            "main"
            "develop"
          ];
        };

        # --- Performance & Refresh Settings ------------------------------------------
        refresher = {
          # Balanced refresh intervals (seconds)
          refreshInterval = 10; # UI updates
          fetchInterval = 60; # Remote sync
        };

        # --- System Integration -----------------------------------------------------
        os = {
          # Consistent with git-tools.nix editor configuration
          edit = "nvim {{filename}}";
          editAtLine = "nvim +{{line}} {{filename}}";
        };

        # --- Update Management ------------------------------------------------------
        update = {
          method = "prompt"; # User control over updates
          days = 14; # Check bi-weekly
        };
      };
    };
  };

  # --- SSH Signing Activation Script ---------------------------------------------
  home.activation.setupGitSSHSigning = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.bash}/bin/bash -c '
          # Source SSH utilities and set up Git signing if SSH keys are available
          SSH_SETUP_SCRIPT="${userConfig.flakeRoot}/scripts/ssh-setup.sh"

          if [[ -x "$SSH_SETUP_SCRIPT" ]]; then
            echo "Setting up Git SSH signing with available keys..."
            "$SSH_SETUP_SCRIPT" update 2>/dev/null || true
          fi

          # Ensure Git config directory exists
          mkdir -p "${config.xdg.configHome}/git"

          # Create minimal allowed signers file if none exists
          if [[ ! -f "${config.xdg.configHome}/git/allowed_signers" ]]; then
            cat > "${config.xdg.configHome}/git/allowed_signers" <<EOF
    # Git SSH Allowed Signers
    # This file will be automatically populated when SSH keys are configured
    # Run: ssh-setup.sh update
    EOF
          fi
        '
  '';

  # --- GitHub SSH Integration ---------------------------------------------------
  home.activation.setupGitHubSSH = lib.hm.dag.entryAfter [ "setupGitSSHSigning" ] ''
    $DRY_RUN_CMD ${pkgs.bash}/bin/bash -c '
      # Ensure GitHub is using the same SSH configuration as git
      if command -v gh &> /dev/null && command -v ssh-add &> /dev/null; then
        # Check if we have SSH keys available
        if ssh-add -l &> /dev/null; then
          echo "GitHub CLI: SSH authentication ready"

          # Verify GitHub SSH connection (non-blocking)
          if timeout 5 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            echo "GitHub CLI: SSH connection verified"
          fi
        fi
      fi
    '
  '';

  # --- XDG Configuration Files --------------------------------------------------
  xdg.configFile = {
    # --- 1Password Integration ---------------------------------------------------
    # Template for GitHub authentication via 1Password
    "secrets/github.env".text = ''
      # GitHub CLI Authentication via 1Password
      # Use with: secrets-manager env github.env gh <command>

      GITHUB_TOKEN=op://Private/github-token/credential
      GH_TOKEN=op://Private/github-token/credential
    '';

    # --- Documentation -----------------------------------------------------------
    "gh/README.md".text = ''
      # GitHub CLI Configuration

      ## Authentication

      ### 1Password Integration
      ```bash
      # Authenticate via 1Password
      secrets-manager env github.env gh auth login

      # Verify authentication
      secrets-manager run gh auth status
      ```

      ### SSH Keys
      GitHub CLI inherits SSH configuration from git. SSH signing keys
      are automatically configured when available.

      ## Key Aliases (via programs.gh)

      ### Pull Requests
      - `ghco <pr>` - Checkout PR locally
      - `ghpc` - Create PR in browser
      - `ghpv` - View PR in browser
      - `ghpm` - Merge PR (squash + delete branch)
      - `ghpl` - List my PRs
      - `ghps` - PR status overview

      ### Repository
      - `ghrv` - View repo in browser
      - `ghrc <repo>` - Clone repository
      - `ghrf` - Fork repository

      ### Issues
      - `ghil` - List assigned issues
      - `ghic` - Create issue in browser
      - `ghiv` - View issue in browser

      ### Workflows
      - `ghwl` - List workflows
      - `ghwr <workflow>` - Run workflow
      - `ghwv` - View workflow
      - `ghruns` - Recent workflow runs

      ## Shell Integration

      Additional git aliases available in shell (see git-tools.nix):
      - `lg` - Launch lazygit TUI
      - `g` - Base git command
      - `gh` - Base GitHub CLI command

      ## Environment Variables

      - `GH_CONFIG_DIR`: ${config.xdg.configHome}/gh (XDG-compliant)
      - `GH_PAGER`: "" (disabled for scripting)
      - `GITHUB_TOKEN`: Via 1Password (secrets-manager)

      ## Advanced Usage

      ### API Access
      ```bash
      # Direct API calls
      gh api /user
      gh api repos/:owner/:repo/issues

      # Search
      gh search repos "language:nix stars:>100"
      gh search issues "label:bug state:open"
      ```

      ### Workflow Management
      ```bash
      # List and run workflows
      gh wl
      gh wr <workflow>
      gh runs
      ```
    '';
  };
}
