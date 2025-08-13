# Title         : deploy.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : flake/deploy.nix
# ---------------------------------------
# Deploy-rs configuration for remote deployment
{ inputs, userConfig, ... }:
{
  # --- Flake Configuration ------------------------------------------------------
  flake = _: {
    # --- Deploy-rs Configuration ----------------------------------------------
    deploy = {
      # --- Rollback Settings ------------------------------------------------
      autoRollback = true;
      magicRollback = true;

      # --- Node Definitions --------------------------------------------------
      nodes = {
        # Local machine (default)
        localhost = {
          hostname = "localhost";
          profiles.system = {
            sshUser = userConfig.username;
            path = inputs.deploy-rs.lib.aarch64-darwin.activate.darwin inputs.self.darwinConfigurations.default;
            user = "root";
            sshOpts = [
              "-o"
              "ConnectTimeout=10"
            ];
          };
        };
        # Remote machine (universal)
        remote = {
          hostname = "remote.local";
          profiles.system = {
            sshUser = userConfig.username;
            path = inputs.deploy-rs.lib.aarch64-darwin.activate.darwin inputs.self.darwinConfigurations.default;
            user = "root";

            # SSH options for reliability
            sshOpts = [
              "-o"
              "ConnectTimeout=10"
              "-o"
              "StrictHostKeyChecking=accept-new"
            ];

            # Health check after deployment
            activation = ''
              echo "Verifying deployment..."

              # Check if nix-darwin is responsive
              if ! /run/current-system/sw/bin/darwin-rebuild --help >/dev/null 2>&1; then
                echo "ERROR: darwin-rebuild not responsive"
                exit 1
              fi

              # Check if nix daemon is running
              if ! launchctl list | grep -q org.nixos.nix-daemon; then
                echo "ERROR: Nix daemon not running"
                exit 1
              fi

              echo "Deployment health check passed"
            '';
          };
        };

        # Example additional servers (uncomment and configure as needed):

        # # MacOS Server Example
        # server1 = {
        #   hostname = "server1.example.com";
        #   profiles.system = {
        #     sshUser = userConfig.username;
        #     path = inputs.deploy-rs.lib.aarch64-darwin.activate.darwin inputs.self.darwinConfigurations.server1;
        #     user = "root";
        #     sshOpts = [
        #       "-o" "ConnectTimeout=10"
        #       "-o" "StrictHostKeyChecking=accept-new"
        #       "-i" "~/.ssh/server1_key"  # Optional: specific SSH key
        #     ];
        #   };
        # };

        # # Linux/NixOS Server Example
        # nixos-server = {
        #   hostname = "nixos.example.com";
        #   profiles.system = {
        #     sshUser = "deploy";
        #     path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.nixos-server;
        #     user = "root";
        #     sshOpts = [
        #       "-o" "ConnectTimeout=10"
        #       "-o" "StrictHostKeyChecking=accept-new"
        #       "-p" "2222"  # Custom SSH port
        #     ];
        #   };
        # };

        # # Docker/VM Example
        # vm-test = {
        #   hostname = "192.168.1.100";
        #   profiles.system = {
        #     sshUser = userConfig.username;
        #     path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.vm-test;
        #     user = "root";
        #   };
        # };
      };
    };

    # --- Deploy-rs Checks ---------------------------------------------------
    checks = builtins.mapAttrs (
      _system: deployLib: deployLib.deployChecks inputs.self.deploy
    ) inputs.deploy-rs.lib;
  };

  # --- Per-System Configuration -------------------------------------------------
  perSystem =
    { system, ... }:
    {
      # --- Deploy Application -----------------------------------------------
      apps.deploy = {
        type = "app";
        program = "${inputs.deploy-rs.packages.${system}.default}/bin/deploy";
      };
    };
}
