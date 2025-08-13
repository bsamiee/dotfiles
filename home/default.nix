# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/default.nix
# ---------------------------------------
{
  pkgs,
  lib,
  userConfig,
  myLib,
  ...
}:

let
  # --- Package Suite Configuration ----------------------------------------------
  # Direct configuration without module system overhead
  isDarwin = myLib.isDarwin pkgs.system;

  packageSuites = {
    # Always enabled core suites
    core.enable = true;
    network.enable = true;
    nix.enable = true;

    # Development language suites
    development = {
      python = {
        enable = true;
        global = true; # Install globally vs devShell only
      };
      node = {
        enable = true;
        global = true;
      };
      lua = {
        enable = true;
        global = true;
      };
      rust = {
        enable = true; # Rust development tooling
        global = true; # Install globally for TUI and agent development
      };
      go = {
        enable = false; # Not used currently
        global = false;
      };
    };

    # Tool suites
    tools = {
      development.enable = true;
      devops = {
        enable = true;
        kubernetes = true;
      };
      media.enable = true;
    };

    # Platform-specific
    macos.enable = isDarwin;
  };
in
{
  # --- Module Imports -----------------------------------------------------------
  imports = [
    # Static config profile files
    ./modules/environment.nix
    ./modules/scripts.nix
    # Nix-managed config profiles
    ./programs/zsh.nix
    ./programs/git-tools.nix
    ./programs/ssh.nix
    ./programs/shell-tools.nix
    ./modules/fonts.nix
    ./modules/file-management.nix
  ];

  # --- Shell Aliases ------------------------------------------------------------
  home.shellAliases =
    let
      # Import alias categories
      nix = import ./aliases/nix.nix { inherit lib; };
      sysadmin = import ./aliases/sysadmin.nix { inherit lib; };
      git-tools = import ./aliases/git-tools.nix { inherit lib; };
      macos = import ./aliases/macos.nix { inherit lib; };
      core = import ./aliases/core.nix { inherit lib; };
      utilities = import ./aliases/utilities.nix { inherit lib; };
      lua = import ./aliases/lua.nix { inherit lib; };
      shell-tools = import ./aliases/shell-tools.nix { inherit lib pkgs; };
      devops = import ./aliases/devops.nix { inherit lib; };
      rust = import ./aliases/rust.nix { inherit lib; };
    in
    lib.mkMerge [
      core.aliases # Modern CLI tools (load first, can be overridden)
      nix.aliases
      sysadmin.aliases
      git-tools.aliases
      shell-tools.aliases # Shell scripting development tools
      utilities.aliases # Power user utilities and launchers
      lua.aliases
      devops.aliases # Docker, Colima, container tools
      (lib.mkIf (
        packageSuites.development.rust.enable && packageSuites.development.rust.global
      ) rust.aliases)
      macos.aliases
    ];

  # --- Home Manager Configuration -----------------------------------------------
  home = {
    # Package management - direct conditional loading based on configuration
    packages = lib.mkMerge [
      # Core suite - essential tools
      (lib.optionals packageSuites.core.enable (import ./modules/packages/core.nix { inherit pkgs; }))
      # Network tools
      (lib.optionals packageSuites.network.enable (
        import ./modules/packages/network.nix { inherit pkgs; }
      ))
      # Nix development tools
      (lib.optionals packageSuites.nix.enable (import ./modules/packages/nix-tools.nix { inherit pkgs; }))
      # Python development suite
      (lib.optionals (
        packageSuites.development.python.enable && packageSuites.development.python.global
      ) (import ./modules/packages/python.nix { inherit pkgs; }))
      # Node.js development suite
      (lib.optionals (packageSuites.development.node.enable && packageSuites.development.node.global) (
        import ./modules/packages/node.nix { inherit pkgs; }
      ))
      # Lua development suite
      (lib.optionals (packageSuites.development.lua.enable && packageSuites.development.lua.global) (
        import ./modules/packages/lua.nix { inherit pkgs; }
      ))
      # Rust development suite
      (lib.optionals (packageSuites.development.rust.enable && packageSuites.development.rust.global) (
        import ./modules/packages/rust.nix { inherit pkgs; }
      ))
      # General development tools
      (lib.optionals packageSuites.tools.development.enable (
        import ./modules/packages/development.nix { inherit pkgs; }
      ))
      # DevOps tools
      (lib.optionals packageSuites.tools.devops.enable (
        import ./modules/packages/devops.nix {
          inherit pkgs lib;
          inherit (packageSuites.tools.devops) kubernetes;
        }
      ))
      # Media processing tools
      (lib.optionals packageSuites.tools.media.enable (
        import ./modules/packages/media.nix { inherit pkgs; }
      ))
      # macOS-specific tools
      (lib.optionals packageSuites.macos.enable (import ./modules/packages/macos.nix { inherit pkgs; }))
    ];
    # Core settings
    stateVersion = "25.05";
    inherit (userConfig) username;
    homeDirectory = userConfig.userHome;

    # --- Local Customization File -----------------------------------------------
    # This stays in default.nix as it's a special case for user overrides
    file.".zshrc.local" = {
      text = ''
        # Add your local customizations here
        # This file won't be overwritten by Nix
        # Use for:
        # - Tools installed outside of Nix that need shell integration
        # - Temporary aliases or functions
        # - Personal tweaks you're testing before adding to Nix config
      '';
      onChange = ''
        if [ -f "$HOME/.zshrc.local" ] && [ -s "$HOME/.zshrc.local" ]; then
          rm "$HOME/.zshrc.local.new"
        else
          mv "$HOME/.zshrc.local.new" "$HOME/.zshrc.local"
        fi
      '';
    };

    # Activation Scripts
    activation = {
      # Example: ensure directories exist
      ensureDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p $HOME/.local/bin
        mkdir -p $HOME/bin
      '';
    };
  };

  # --- Platform Integration ---------------------------------------------------
  targets.darwin.linkApps.enable = true;
}
