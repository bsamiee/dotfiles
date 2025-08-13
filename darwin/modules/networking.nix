# Title         : networking.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : darwin/modules/networking.nix
# ---------------------------------------
# Network and firewall configuration
{ myLib, ... }:

{
  # --- Application Layer Firewall (replaces deprecated system.defaults.alf) ---
  networking.applicationFirewall = {
    enable = myLib.default true; # Enable firewall
    allowSigned = myLib.default true; # Allow signed applications
    allowSignedApp = myLib.default false; # Stricter for downloaded signed apps
    enableStealthMode = myLib.default true; # Drop ICMP (stealth mode)
    blockAllIncoming = myLib.default false; # Don't block all (too restrictive)
  };
}