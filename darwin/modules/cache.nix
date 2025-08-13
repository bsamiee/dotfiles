# Title         : cache.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/modules/cache.nix
# ---------------------------------------
# Unified cache configuration - binary caches, Cachix, and garbage collection
{
  pkgs,
  userConfig,
  ...
}:

let
  cacheName = userConfig.username;

  # --- System-Level Scripts -------------------------------------------------------
  cachixDaemon = pkgs.writeShellScriptBin "cachix-daemon-wrapper" ''
    set -euo pipefail

    if ! ${pkgs.cachix}/bin/cachix authtoken &>/dev/null; then
      echo "Cachix not authenticated. Run: cachix authtoken"
      exit 0
    fi

    if ! pgrep -x "cachix" > /dev/null; then
      echo "Starting Cachix daemon for concurrent pushing..."
      ${pkgs.cachix}/bin/cachix daemon &
    fi
  '';

  # Post-build hook for Cachix (temporarily disabled)
  cachixHook = pkgs.writeScript "cachix-post-build-hook" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    ${pkgs.cachix}/bin/cachix authtoken &>/dev/null || exit 0
    echo "Pushing to cache: ${cacheName}"
    exec ${pkgs.cachix}/bin/cachix push "${cacheName}" $OUT_PATHS
  '';
in
{
  # --- System Packages -----------------------------------------------------------
  environment.systemPackages = with pkgs; [
    cachix
    cachixDaemon
  ];

  # --- Nix Configuration --------------------------------------------------------
  nix = {
    # Binary cache settings
    settings = {
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://bsamiee.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Ky7bkq5CX+/rkCWyvRCYg3Fs="
        "bsamiee.cachix.org-1:b/WAIj/ImX6pkDc6SUVYHJoL/yJ7E4MIA+e7uA9rdwQ="
      ];
      narinfo-cache-negative-ttl = 60;
      narinfo-cache-positive-ttl = 86400;
      eval-cache = true;
      tarball-ttl = 300;
      builders-use-substitutes = true;
      post-build-hook = cachixHook;
      http-connections = 50;
      connect-timeout = 5;
      stalled-download-timeout = 300;
    };

    # Garbage collection
    gc = {
      automatic = true;
      interval = {
        Hour = 3;
        Minute = 0;
        Weekday = 0;
      };
      options = "--delete-older-than 7d --max-freed $((5 * 1024 * 1024 * 1024))";
    };

    # Store optimization
    optimise.automatic = true;
  };

  # --- Cachix Daemon Service (macOS launchd) ------------------------------------
  launchd.user.agents.cachix-daemon = {
    serviceConfig = {
      ProgramArguments = [
        "${cachixDaemon}/bin/cachix-daemon-wrapper"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/tmp/cachix-daemon.log";
      StandardErrorPath = "/tmp/cachix-daemon.error.log";
    };
  };
}
