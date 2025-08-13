#!/usr/bin/env bash
# Title         : nix-health.sh
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : scripts/nix-health.sh
# ---------------------------------------
# Comprehensive Nix system health check and diagnostics

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- System Health Checks ---
printf "%-25s" "Nix daemon:"
if launchctl list | grep -q org.nixos.nix-daemon; then
	echo -e "${GREEN}OK${NC}"
else
	echo -e "${RED}FAIL${NC}"
fi

# --- Store Metrics ---
echo -e "\n${YELLOW}Store Metrics:${NC}"
printf "%-25s" "Store size:"
STORE_SIZE=$(du -sh /nix/store 2>/dev/null | cut -f1 || echo "N/A")
echo "$STORE_SIZE"

printf "%-25s" "Store path count:"
find /nix/store -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' '

# --- Garbage Collection ---
echo -e "\n${YELLOW}Garbage Collection:${NC}"
printf "%-25s" "Dead paths:"
nix-store --gc --print-dead 2>/dev/null | wc -l | tr -d ' ' || echo "0"

printf "%-25s" "GC roots:"
nix-store --gc --print-roots 2>/dev/null | wc -l | tr -d ' ' || echo "0"

printf "%-25s" "Last GC:"
if [ -f /nix/var/nix/gcroots/auto ]; then
	stat -f "%Sm" -t "%Y-%m-%d %H:%M" /nix/var/nix/gcroots/auto 2>/dev/null || echo "Never"
else
	echo "Never"
fi

# --- Generations ---
echo -e "\n${YELLOW}Generations:${NC}"
printf "%-25s" "Darwin generations:"
darwin-rebuild --list-generations 2>/dev/null | wc -l | tr -d ' ' || echo "0"

printf "%-25s" "Oldest generation:"
darwin-rebuild --list-generations 2>/dev/null | head -1 | awk '{print $3}' || echo "N/A"

# --- Cache Status ---
echo -e "\n${YELLOW}Cache Status:${NC}"
printf "%-25s" "Cachix configured:"
if cachix authtoken &>/dev/null 2>&1; then
	echo -e "${GREEN}Yes${NC}"
else
	echo -e "${YELLOW}No${NC}"
fi

printf "%-25s" "Cachix daemon:"
if pgrep -x "cachix" >/dev/null; then
	echo -e "${GREEN}Running${NC}"
else
	echo -e "${YELLOW}Not running${NC}"
fi

printf "%-25s" "Substituters:"
nix show-config 2>/dev/null | grep -c "^substituters" || echo "0"

# --- Build Performance ---
echo -e "\n${YELLOW}Build Performance:${NC}"
printf "%-25s" "Eval cache enabled:"
if nix show-config 2>/dev/null | grep -q "eval-cache = true"; then
	echo -e "${GREEN}Yes${NC}"
else
	echo -e "${RED}No${NC}"
fi

printf "%-25s" "Max jobs:"
nix show-config 2>/dev/null | grep "max-jobs" | awk '{print $3}' || echo "auto"

# --- Broken Symlinks ---
echo -e "\n${YELLOW}Maintenance:${NC}"
printf "%-25s" "Broken result links:"
find ~ -maxdepth 3 -type l -name "result*" ! -exec test -e {} \; 2>/dev/null | wc -l | tr -d ' '

# --- Disk Usage ---
echo -e "\n${YELLOW}Disk Usage:${NC}"
df -h /nix/store ~ | tail -n +2 | while read -r line; do
	echo "  $line"
done

# --- Recommendations ---
echo -e "\n${YELLOW}Recommendations:${NC}"
DEAD_COUNT=$(nix-store --gc --print-dead 2>/dev/null | wc -l | tr -d ' ')
if [ "$DEAD_COUNT" -gt 100 ]; then
	echo "  • Run 'ngc' to clean ${DEAD_COUNT} dead paths"
fi

BROKEN_LINKS=$(find ~ -maxdepth 3 -type l -name "result*" ! -exec test -e {} \; 2>/dev/null | wc -l | tr -d ' ')
if [ "$BROKEN_LINKS" -gt 0 ]; then
	echo "  • Clean broken links: find ~ -maxdepth 3 -type l -name 'result*' ! -exec test -e {} \\; -delete"
fi

if ! cachix authtoken &>/dev/null 2>&1; then
	echo "  • Configure Cachix: run 'cachix authtoken' for faster builds"
fi

echo -e "\n${GREEN}Health check complete!${NC}"
