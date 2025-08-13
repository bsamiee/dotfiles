# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/hosts/default.nix
# ---------------------------------------
# Default machine configuration
{
  ...
}:

{
  imports = [
    ./base.nix
  ];

  # Default machine (current development machine)
  # Uses base configuration without modifications
}
