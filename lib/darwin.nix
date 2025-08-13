# Title         : darwin.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : lib/darwin.nix
# ---------------------------------------
# Darwin-specific helper functions for macOS system management
{
  lib,
  pkgs,
  userConfig,
  ...
}:

{
  # --- LaunchD Service Helpers -----------------------------------------------------
  mkLaunchdAgent =
    name:
    {
      script,
      interval ? null,
      environment ? { },
      logDir ? null,
      runAtLoad ? false,
      keepAlive ? false,
    }:
    {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          script
        ];
      }
      // (lib.optionalAttrs (logDir != null) {
        StandardOutPath = "${logDir}/${name}.out.log";
        StandardErrorPath = "${logDir}/${name}.error.log";
      })
      // (lib.optionalAttrs (interval != null) {
        StartInterval = interval;
      })
      // (lib.optionalAttrs (environment != { }) {
        EnvironmentVariables = environment;
      })
      // (lib.optionalAttrs runAtLoad {
        RunAtLoad = true;
      })
      // (lib.optionalAttrs keepAlive {
        KeepAlive = true;
      });
    };

  # --- Activation Script Helpers ---------------------------------------------------
  # Create a standardized activation script with consistent logging
  mkActivationScript = _name: description: script: {
    text = ''
      echo "Setting up ${description}..."
      ${script}
      echo "${description} setup complete"
    '';
  };

  # Create an activation script with error handling
  mkActivationScriptSafe = _name: description: script: {
    text = ''
      echo "Setting up ${description}..."
      if ${script}; then
        echo "${description} setup complete"
      else
        echo "WARNING: ${description} setup had issues (non-fatal)"
      fi
    '';
  };

  # --- Directory Management Helpers ------------------------------------------------
  # Create a directory with specific permissions and optional owner
  mkDirWithPerms = path: mode: owner: ''
    if [ ! -d "${path}" ]; then
      mkdir -p "${path}"
      ${lib.optionalString (owner != null) "chown ${owner} '${path}'"}
      chmod ${mode} "${path}"
    fi
  '';

  # --- XDG Runtime Directory Helper ------------------------------------------------
  # Common pattern for XDG runtime directory management
  mkXdgRuntimeScript = xdgDirs: ''
    # Ensure log directory exists
    mkdir -p "${xdgDirs.stateHome}/logs"

    RUNTIME_DIR="${xdgDirs.runtimeDir}"

    if [ ! -d "$RUNTIME_DIR" ]; then
      sudo mkdir -p "$RUNTIME_DIR"
      sudo chown ${userConfig.username}:staff "$RUNTIME_DIR"
      sudo chmod 700 "$RUNTIME_DIR"
    fi

    # Ensure proper ownership (use current user check instead of uid)
    if [ "$(stat -f %Su "$RUNTIME_DIR")" != "${userConfig.username}" ]; then
      sudo chown ${userConfig.username}:staff "$RUNTIME_DIR"
      sudo chmod 700 "$RUNTIME_DIR"
    fi
  '';

}
