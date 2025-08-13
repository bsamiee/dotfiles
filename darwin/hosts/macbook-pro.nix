# Title         : macbook-pro.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/hosts/macbook-pro.nix
# ---------------------------------------
# Example machine-specific configuration (currently unused - reference only)

{
  imports = [
    ./base.nix
  ];

  networking.hostName = "macbook-pro";
}
