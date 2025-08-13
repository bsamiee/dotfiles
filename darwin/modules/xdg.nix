# Title         : xdg.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/modules/xdg.nix
# ---------------------------------------
{
  pkgs,
  lib,
  userConfig,
  ...
}:

let
  darwinLib = import ../../lib/darwin.nix { inherit lib pkgs userConfig; };
  # --- XDG Variable Definitions -------------------------------------------------
  xdgDirs = {
    # XDG base directories following the specification
    configHome = "${userConfig.userHome}/.config";
    dataHome = "${userConfig.userHome}/.local/share";
    stateHome = "${userConfig.userHome}/.local/state";
    cacheHome = "${userConfig.userHome}/.cache";
    # macOS doesn't have /run/user, use ~/Library/Caches for runtime data
    runtimeDir = "${userConfig.userHome}/Library/Caches/TemporaryItems";
  };
  cacheExclusions = [
    # Directories that should be excluded from Time Machine backups
    xdgDirs.cacheHome
    "${xdgDirs.dataHome}/Trash"
    "${xdgDirs.stateHome}/logs"
    "${xdgDirs.dataHome}/backups" # Exclude backups from Time Machine
    "${userConfig.userHome}/.npm"
    "${xdgDirs.dataHome}/cargo/registry"
    "${userConfig.userHome}/.cache/pip"
    "${xdgDirs.cacheHome}/pypoetry"
    "${xdgDirs.cacheHome}/ruff"
    "${xdgDirs.dataHome}/pipx"
    "${xdgDirs.cacheHome}/sccache"
    "${xdgDirs.cacheHome}/shellcheck"
    "${xdgDirs.cacheHome}/npm"
  ];
  xdgStructure = [
    # Directories that should be created with proper permissions
    # Core XDG directories
    {
      path = xdgDirs.configHome;
      mode = "755";
    }
    {
      path = xdgDirs.dataHome;
      mode = "755";
    }
    {
      path = xdgDirs.stateHome;
      mode = "755";
    }
    {
      path = xdgDirs.cacheHome;
      mode = "755";
    }
    # Common subdirectories
    {
      path = "${xdgDirs.configHome}/git";
      mode = "755";
    }
    {
      path = "${xdgDirs.configHome}/nix";
      mode = "755";
    }
    {
      path = "${xdgDirs.configHome}/nvim";
      mode = "755";
    }
    {
      path = "${xdgDirs.configHome}/luarocks";
      mode = "755";
    }
    {
      path = "${xdgDirs.dataHome}/applications";
      mode = "755";
    }
    {
      path = "${xdgDirs.dataHome}/fonts";
      mode = "755";
    }
    {
      path = "${xdgDirs.dataHome}/icons";
      mode = "755";
    }
    {
      path = "${xdgDirs.stateHome}/nix";
      mode = "755";
    }
    {
      path = "${xdgDirs.stateHome}/logs";
      mode = "755";
    }
    {
      path = "${xdgDirs.cacheHome}/nix";
      mode = "755";
    }
    {
      path = "${xdgDirs.cacheHome}/fontconfig";
      mode = "755";
    }
    {
      path = "${xdgDirs.configHome}/pypoetry";
      mode = "755";
    }
    {
      path = "${xdgDirs.configHome}/ipython";
      mode = "755";
    }
    {
      path = "${xdgDirs.configHome}/jupyter";
      mode = "755";
    }
    {
      path = "${xdgDirs.cacheHome}/basedpyright";
      mode = "755";
    }
    {
      path = "${xdgDirs.cacheHome}/uv";
      mode = "755";
    }
    {
      path = "${xdgDirs.configHome}/typescript";
      mode = "755";
    }
    {
      path = "${xdgDirs.configHome}/eslint";
      mode = "755";
    }
    {
      path = "${xdgDirs.configHome}/gh";
      mode = "755";
    }
    {
      path = "${xdgDirs.configHome}/lazygit";
      mode = "755";
    }
    {
      path = "${xdgDirs.dataHome}/pipx";
      mode = "755";
    }
    {
      path = "${userConfig.userHome}/.ssh/sockets";
      mode = "700";
    }
    {
      path = "${xdgDirs.configHome}/marksman";
      mode = "755";
    }
    {
      path = "${xdgDirs.configHome}/wezterm";
      mode = "755";
    }
    {
      path = "${xdgDirs.configHome}/shellcheck";
      mode = "755";
    }
    {
      path = "${xdgDirs.configHome}/npm";
      mode = "755";
    }
    {
      path = "${xdgDirs.configHome}/docker";
      mode = "755";
    }
    {
      path = "${xdgDirs.stateHome}/bash";
      mode = "755";
    }
    {
      path = "${xdgDirs.stateHome}/less";
      mode = "755";
    }
    {
      path = "${xdgDirs.dataHome}/backups";
      mode = "755";
    }
    {
      path = "${xdgDirs.configHome}/rust-analyzer";
      mode = "755";
    }
    {
      path = "${xdgDirs.cacheHome}/rust-analyzer";
      mode = "755";
    }
    {
      path = "${xdgDirs.cacheHome}/cargo";
      mode = "755";
    }
    {
      path = "${xdgDirs.dataHome}/cargo";
      mode = "755";
    }
    {
      path = "${xdgDirs.dataHome}/rustup";
      mode = "755";
    }
    {
      path = "${xdgDirs.cacheHome}/sccache";
      mode = "755";
    }
    {
      path = "${xdgDirs.cacheHome}/shellcheck";
      mode = "755";
    }
    {
      path = "${xdgDirs.cacheHome}/npm";
      mode = "755";
    }
  ];
in
{
  # --- Launchd Configuration ----------------------------------------------------
  # XDG environment variables now defined in home/modules/environment.nix
  # Set in launchd environment for GUI applications
  launchd = {
    user = {
      envVariables = {
        XDG_CONFIG_HOME = xdgDirs.configHome;
        XDG_DATA_HOME = xdgDirs.dataHome;
        XDG_STATE_HOME = xdgDirs.stateHome;
        XDG_CACHE_HOME = xdgDirs.cacheHome;
        XDG_RUNTIME_DIR = xdgDirs.runtimeDir;
      };

      # LaunchD agents
      agents.xdg-runtime-dir =
        darwinLib.mkLaunchdAgent "xdg-runtime-dir" {
          script = darwinLib.mkXdgRuntimeScript xdgDirs + ''
            find "${xdgDirs.runtimeDir}" -type f -mtime +1 -delete 2>/dev/null || true
          '';
          interval = 3600;
          runAtLoad = true;
          logDir = "${xdgDirs.stateHome}/logs";
        }
        // {
          serviceConfig = {
            ProcessType = "Background";
            Nice = 15;
          };
        };

      # Temporary file management - using helper for script part
      agents.xdg-temp-cleanup =
        darwinLib.mkLaunchdAgent "xdg-temp-cleanup" {
          script = ''
            echo "Cleaning XDG temporary files at $(date)"

            # Use our XDG cleanup helper plus custom logic
            find "${xdgDirs.cacheHome}" -type f -atime +30 -delete 2>/dev/null || true
            find "${xdgDirs.cacheHome}" -type d -empty -delete 2>/dev/null || true

            if [ -d "${userConfig.userHome}/.npm" ]; then
              find "${userConfig.userHome}/.npm" -type f -atime +14 -delete 2>/dev/null || true
            fi

            if [ -d "${xdgDirs.cacheHome}/pip" ]; then
              find "${xdgDirs.cacheHome}/pip" -type f -atime +30 -delete 2>/dev/null || true
            fi

            # Clean font cache if it gets too large (>100MB)
            FONT_CACHE="${xdgDirs.cacheHome}/fontconfig"
            if [ -d "$FONT_CACHE" ]; then
              SIZE=$(du -sm "$FONT_CACHE" | cut -f1)
              if [ "$SIZE" -gt 100 ]; then
                echo "Font cache is ''${SIZE}MB, cleaning..."
                rm -rf "$FONT_CACHE"/*
                fc-cache -f 2>/dev/null || true
              fi
            fi

            echo "Temporary file cleanup completed at $(date)"
          '';
          logDir = "${xdgDirs.stateHome}/logs";
        }
        // {
          serviceConfig = {
            StartCalendarInterval = [
              {
                Weekday = 1;
                Hour = 3;
                Minute = 30;
              } # Monday at 3:30 AM
              {
                Weekday = 4;
                Hour = 3;
                Minute = 30;
              } # Thursday at 3:30 AM
            ];
            ProcessType = "Background";
            Nice = 15;
          };
        };
    };
  };

  # --- Activation Scripts -------------------------------------------------------
  system.activationScripts = {
    # XDG directory creation
    xdgDirectories = darwinLib.mkActivationScript "xdgDirectories" "XDG directory structure" ''
      # Create all directories in parallel for speed
      ${lib.concatMapStrings (dir: ''
        mkdir -pm ${dir.mode} "${dir.path}" &
      '') xdgStructure}
      wait

      # Runtime directory is managed by launchd agent xdg-runtime-dir
    '';

    # Time Machine exclusions for cache directories
    xdgTimeMachineExclusions =
      darwinLib.mkActivationScript "xdgTimeMachineExclusions"
        "Time Machine exclusions for XDG cache directories"
        ''
          ${lib.concatMapStringsSep "\n" (dir: ''
            if [ -d "${dir}" ]; then
              tmutil addexclusion "${dir}" 2>/dev/null || true
              echo "Excluded ${dir} from Time Machine"
            fi
          '') cacheExclusions}
        '';

    # Application-specific XDG migrations
    xdgMigrations = darwinLib.mkActivationScriptSafe "xdgMigrations" "XDG application migrations" ''
      if [ -f "${userConfig.userHome}/.gitconfig" ] && [ ! -f "${xdgDirs.configHome}/git/config" ]; then
        ${darwinLib.mkDirWithPerms "${xdgDirs.configHome}/git" "755" null}
        cp "${userConfig.userHome}/.gitconfig" "${xdgDirs.configHome}/git/config"
        echo "Migrated git config to XDG location"
      fi

      if [ -f "${userConfig.userHome}/.npmrc" ] && [ ! -f "${xdgDirs.configHome}/npm/npmrc" ]; then
        ${darwinLib.mkDirWithPerms "${xdgDirs.configHome}/npm" "755" null}
        cp "${userConfig.userHome}/.npmrc" "${xdgDirs.configHome}/npm/npmrc"
        echo "Migrated npm config to XDG location"
      fi

      # Create XDG compliance wrapper for npm
      if command -v npm &> /dev/null; then
        export npm_config_cache="${xdgDirs.cacheHome}/npm"
        export npm_config_userconfig="${xdgDirs.configHome}/npm/npmrc"
      fi
    '';
  };

  # --- Nix & System Integration -------------------------------------------------
  # Note: use-xdg-base-directories is set in darwin/modules/settings.nix
  # Update environment.profiles to include XDG-compliant paths
  environment.profiles = lib.mkBefore [
    "${xdgDirs.stateHome}/nix/profile"
    "${xdgDirs.dataHome}/nix-defexpr/channels"
  ];
}
