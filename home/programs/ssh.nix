# Title         : ssh.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/programs/ssh.nix
# ---------------------------------------
# SSH client configuration with 1Password integration using home-manager

{
  pkgs,
  lib,
  userConfig,
  ...
}:

let
  # Platform-aware 1Password SSH agent socket path
  onePasswordSocket =
    if pkgs.stdenv.isDarwin then
      "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else
      "~/.1password/agent.sock";
in
{
  programs.ssh = {
    enable = true;

    # --- SSH Configuration ---------------------------------------------------
    extraConfig = ''
      # === 1Password SSH Agent Integration ===
      # Use 1Password SSH agent for all hosts by default
      Host *
        # 1Password SSH agent (platform-aware path)
        IdentityAgent "${onePasswordSocket}"

        # Enhanced SSH settings
        AddKeysToAgent yes
        UseKeychain yes

        # Connection multiplexing for performance
        ControlMaster auto
        ControlPath ~/.ssh/sockets/%h-%p-%r
        ControlPersist 600

        # Security settings
        StrictHostKeyChecking ask
        ForwardAgent no

        # Keep connections alive
        ServerAliveInterval 60
        ServerAliveCountMax 3

        # Compression for slow connections
        Compression yes

        # Prefer IPv4 for compatibility
        AddressFamily inet
    '';

    # --- Host-Specific Configurations ----------------------------------------
    matchBlocks = {
      # Local development and testing
      "localhost" = {
        hostname = "localhost";
        user = userConfig.username;
        port = 22;
        identitiesOnly = true;
      };

      # Example: Development server
      "dev" = {
        hostname = "dev.local";
        user = userConfig.username;
        port = 22;
        identitiesOnly = true;
      };

      # Example: Production server (commented out - configure as needed)
      # "prod" = {
      #   hostname = "production.example.com";
      #   user = "deploy";
      #   port = 22;
      #   identitiesOnly = true;
      #   # Optional: specify identity file for this host
      #   # identityFile = "~/.ssh/production_key";
      # };

      # GitHub configuration (optimized for Git operations)
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
        # Prefer SSH over HTTPS for Git operations
        extraOptions = {
          PreferredAuthentications = "publickey";
          PubkeyAuthentication = "yes";
        };
      };

      # GitLab configuration
      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identitiesOnly = true;
        extraOptions = {
          PreferredAuthentications = "publickey";
          PubkeyAuthentication = "yes";
        };
      };
    };
  };

  # --- SSH Directory Setup ------------------------------------------------
  home.file.".ssh/sockets/.keep".text = "# SSH connection multiplexing sockets";

  # Ensure proper SSH directory permissions (activation script)
  home.activation.setupSSHDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.bash}/bin/bash -c '
      # Create SSH directory with proper permissions
      mkdir -p "$HOME/.ssh/sockets"
      chmod 700 "$HOME/.ssh"
      chmod 700 "$HOME/.ssh/sockets"

      # Source SSH utilities if available
      SSH_LIB="${userConfig.flakeRoot}/lib/ssh.sh"
      if [[ -f "$SSH_LIB" ]]; then
        source "$SSH_LIB"

        # Set up SSH environment for current session
        if setup_ssh_environment 2>/dev/null; then
          echo "SSH environment configured with 1Password integration"
        else
          echo "SSH environment setup completed (1Password not available)"
        fi
      fi

      echo "SSH directory setup completed"
    '
  '';
}
