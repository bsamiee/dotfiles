# Title         : settings.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/modules/settings.nix
# ---------------------------------------
# Core Nix settings - cache and GC config moved to cache.nix
{
  config,
  pkgs,
  inputs,
  myLib,
  ...
}:

{
  # --- Nixpkgs Configuration ----------------------------------------------------
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = false;
      allowUnsupportedSystem = false;
    };
    # Use overlays for custom packages if needed
    overlays = [ ];
  };
  # --- Nix Core Configuration ---------------------------------------------------
  nix = {
    # Use latest stable Nix with 2025 features
    package = pkgs.nixVersions.latest;
    settings = {
      # Experimental features (stable subset)
      experimental-features = [
        "nix-command"
        "flakes"
        "auto-allocate-uids"
        "repl-flake"
      ];
      # --- Performance Tuning (cache settings moved to cache.nix) --------------
      cores = 0; # Use all available cores
      max-jobs = "auto"; # Auto-detect optimal parallel jobs
      max-substitution-jobs = 32; # Optimized for faster downloads
      # --- Build Optimization (Resource-Conscious) ------------------------------
      keep-outputs = false; # Don't keep build outputs (saves significant space)
      keep-derivations = false; # Don't keep .drv files (saves space)
      compress-build-log = true; # Compress logs (saves space)
      keep-failed = false; # Don't keep failed builds (saves space)
      # --- Store Optimizations -------------------------------------------------
      # Note: auto-optimise-store is disabled due to corruption risks on macOS
      # Using nix.optimise.automatic instead (configured in cache.nix)
      min-free-check-interval = 300; # Check free space less often
      max-silent-time = 3600; # 1 hour for large builds
      # Storage management
      min-free = myLib.default (4 * 1024 * 1024 * 1024); # 4GB minimum free space
      max-free = myLib.default (16 * 1024 * 1024 * 1024); # 16GB maximum to free
      # macOS optimizations
      sandbox = "relaxed";
      filter-syscalls = false; # Avoid macOS sandbox issues
      use-sqlite-wal = true;
      use-xdg-base-directories = true; # Modern pattern
      # Security (principle of least privilege)
      trusted-users = [
        "@admin"
        "root"
      ];
      allowed-users = [ "*" ];
      # Advanced features
      allow-import-from-derivation = true; # Some packages require this
      warn-dirty = false; # Development-friendly
      accept-flake-config = true; # Trust flake nixConfig
      # 2025: Enhanced error reporting
      show-trace = true;
      log-lines = 100;
    };
    # Garbage collection and store optimization moved to cache.nix, minimal extra options (only essentials)
    extraOptions = ''
      download-attempts = 3
      fallback = true
      keep-build-log = true
    '';

    # Registry for flake commands (use nixpkgs)
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      dotfiles.flake = inputs.self;
    };
    # Channel configuration (for legacy compatibility)
    nixPath = [
      "nixpkgs=${inputs.nixpkgs}"
      "darwin=${inputs.darwin}"
    ];
  };

  # --- System Environment -------------------------------------------------------
  # System packages are managed via home-manager for better user-level control
  environment.systemPackages = [ ];

  # Environment variables
  environment.variables = {
    # Development environment
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  # System programs
  programs = {
    # Note: nix-index is enabled in home-manager instead
    # command-not-found doesn't exist in nix-darwin (NixOS only)
  };
}
