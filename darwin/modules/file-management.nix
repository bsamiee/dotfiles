# Title         : file-management.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/modules/file-management.nix
# ---------------------------------------
# System-level file management and activation scripts

{
  pkgs,
  lib,
  userConfig,
  ...
}:

let
  darwinLib = import ../../lib/darwin.nix { inherit lib pkgs userConfig; };
in

{
  # --- System Defaults ----------------------------------------------------------
  system = {
    defaults = {
      # Configure Spotlight search categories (disable clutter, keep useful ones)
      CustomUserPreferences = {
        "com.apple.spotlight" = {
          orderedItems = [
            {
              enabled = 1;
              name = "APPLICATIONS";
            }
            {
              enabled = 1;
              name = "SYSTEM_PREFS";
            }
            {
              enabled = 1;
              name = "DIRECTORIES";
            }
            {
              enabled = 1;
              name = "DOCUMENTS";
            }
            {
              enabled = 1;
              name = "PDF";
            }
            {
              enabled = 1;
              name = "IMAGES";
            }
            {
              enabled = 1;
              name = "SOURCE";
            }
            {
              enabled = 1;
              name = "CONTACT";
            }
            {
              enabled = 1;
              name = "EVENT_TODO";
            }
            {
              enabled = 1;
              name = "BOOKMARKS";
            }
            {
              enabled = 0;
              name = "MUSIC";
            }
            {
              enabled = 0;
              name = "MOVIES";
            }
            {
              enabled = 0;
              name = "PRESENTATIONS";
            }
            {
              enabled = 0;
              name = "SPREADSHEETS";
            }
            {
              enabled = 0;
              name = "MENU_SPOTLIGHT_SUGGESTIONS";
            }
          ];
        };

        # File Associations
        "com.apple.LaunchServices/com.apple.launchservices.secure" = {
          LSHandlers = [
            # Development files
            {
              LSHandlerContentType = "public.plain-text";
              LSHandlerRoleAll = "com.microsoft.vscode"; # Change to your preferred editor
            }
            {
              LSHandlerContentType = "public.unix-executable";
              LSHandlerRoleAll = "com.microsoft.vscode";
            }
            {
              LSHandlerContentType = "com.netscape.javascript-source";
              LSHandlerRoleAll = "com.microsoft.vscode";
            }
            {
              LSHandlerContentType = "public.json";
              LSHandlerRoleAll = "com.microsoft.vscode";
            }
            # Configuration files
            {
              LSHandlerContentType = "org.yaml.yaml";
              LSHandlerRoleAll = "com.microsoft.vscode";
            }
            # Archive files
            {
              LSHandlerContentType = "public.zip-archive";
              LSHandlerRoleAll = "com.apple.archiveutility"; # Built-in Archive Utility
            }
          ];
        };
      };
      # LaunchServices settings moved to darwin/system/security.nix
    };

    # --- Activation Scripts -------------------------------------------------------
    activationScripts = {
      # Fix nix applications visibility in Spotlight and Launchpad
      nixAppsIntegration = ''
        echo "Configuring nix applications integration..."

        ${darwinLib.mkDirWithPerms "/Applications/Nix Apps" "755" "root:admin"}

        # Link nix-installed apps to main Applications folder for Spotlight indexing
        if [ -d "${userConfig.userHome}/Applications" ]; then
          for app in "${userConfig.userHome}/Applications"/*.app; do
            if [ -e "$app" ]; then
              app_name="$(basename "$app")"
              target="/Applications/Nix Apps/$app_name"

              [ -L "$target" ] && [ ! -e "$target" ] && rm "$target"

              if [ ! -e "$target" ]; then
                ln -sf "$app" "$target"
              fi
            fi
          done
        fi

        # Force LaunchServices to rebuild database for new apps
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
          -kill -r -domain local -domain system -domain user 2>/dev/null || true

        echo "Nix applications integration complete"
      '';

      # Configure Spotlight exclusions for build artifacts and development clutter
      spotlightExclusions = ''
        echo "Configuring Spotlight exclusions..."

        # Exclude /nix store from indexing (performance)
        if [ -d "/nix" ]; then
          ${pkgs.darwin.mDNSResponder}/bin/mdutil -i off -d /nix 2>/dev/null || true
          touch /nix/.metadata_never_index 2>/dev/null || true
        fi

        # Common build artifacts and cache directories to exclude
        # Use single find with multiple patterns for efficiency
        find "${userConfig.userHome}" \
          -type d \
          \( -name "node_modules" \
             -o -name ".git" \
             -o -name "target" \
             -o -name "build" \
             -o -name "dist" \
             -o -name ".next" \
             -o -name ".nuxt" \
             -o -name "__pycache__" \
             -o -name ".pytest_cache" \
             -o -name ".cargo" \
             -o -name ".npm" \
             -o -name ".yarn" \
             -o -name ".cache" \
             -o -name "Library/Caches" \
             -o -name ".local/share/Trash" \) \
          -prune \
          -exec sh -c '
            ${pkgs.darwin.mDNSResponder}/bin/mdutil -i off -d "$1" 2>/dev/null || true
            touch "$1/.metadata_never_index" 2>/dev/null || true
          ' _ {} \;

        echo "Spotlight exclusions configured"
      '';
    };
  };

  # --- Service Definitions ------------------------------------------------------
  # Maintenance service for keeping applications visible
  launchd.user.agents."nix-apps-maintenance" =
    darwinLib.mkLaunchdAgent "nix-apps-maintenance" {
      script = ''
        # Clean up broken symlinks in Nix Apps folder
        if [ -d "/Applications/Nix Apps" ]; then
          find "/Applications/Nix Apps" -type l ! -exec test -e {} \; -delete 2>/dev/null || true
        fi

        # Re-register applications if new ones are detected
        if find "${userConfig.userHome}/Applications" -name "*.app" -newer ~/.nix-apps-last-update 2>/dev/null | grep -q .; then
          /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
            -kill -r -domain local -domain system -domain user 2>/dev/null || true
          touch ~/.nix-apps-last-update
        fi
      '';
      interval = 3600;
    }
    // {
      serviceConfig = {
        ProcessType = "Background";
        Nice = 15;
      };
    };
}
