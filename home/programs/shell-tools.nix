# Title         : shell-tools.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/programs/shell-tools.nix
# ---------------------------------------
# Modern shell tool integrations and enhancements
# These tools provide enhanced shell experience across different shells

{
  config,
  ...
}:

{
  programs = {
    # --- Nix Index ----------------------------------------------------------------
    nix-index = {
      enable = true;
      enableZshIntegration = true; # Provides command-not-found functionality
    };

    # --- Starship Prompt ----------------------------------------------------------
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = builtins.fromTOML (builtins.readFile ../configs/apps/starship.toml);
    };

    # --- FZF (Fuzzy Finder) -------------------------------------------------------
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd --type f --hidden --follow --exclude .git";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
      ];
    };

    # --- Zoxide (Smart Directory Jumper) ------------------------------------------
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    # --- Direnv (Directory Environment) -------------------------------------------
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };

    # --- Eza (ls replacement) -----------------------------------------------------
    eza = {
      enable = true;
      enableZshIntegration = false; # We define our own aliases in shells/aliases.nix
      git = true;
      icons = "auto"; # Changed from boolean to string (deprecated in 24.11)
    };

    # --- Bat (cat replacement) ----------------------------------------------------
    bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        style = "numbers,changes";
      };
    };

    # --- Ripgrep (grep replacement) -----------------------------------------------
    ripgrep = {
      enable = true;
      arguments = [
        "--smart-case"
        "--hidden"
        "--glob=!.git/*"
      ];
    };
  };
}
