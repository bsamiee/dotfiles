# Title         : sysadmin.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : home/shells/aliases/sysadmin.nix
# ---------------------------------------
# System administration aliases - navigation, files, process, network, permissions
_:

{
  aliases = {
    # Navigation & directories
    ".." = "cd .."; # Go up one directory
    "..." = "cd ../.."; # Go up two directories
    "...." = "cd ../../.."; # Go up three directories
    "~" = "cd ~"; # Go to home
    "-" = "cd -"; # Go to previous directory
    mkd = "mkdir -p"; # Make directory with parents

    # System information tools (enhanced bin/audit-tools.sh)
    ta = "audit-tools.sh"; # Tool audit - inventory all installed packages
    tad = "audit-tools.sh -d"; # Tool audit - detailed view
    tam = "audit-tools.sh -m"; # Tool audit - manager specific
    sys = "audit-tools.sh -s"; # System information (hardware, OS, storage)
    net = "audit-tools.sh -n"; # Network information (interfaces, connectivity)
    proc = "audit-tools.sh -p"; # Process information (CPU, memory usage)

    # Process management
    ps = "ps aux"; # List all processes
    psg = "ps aux | grep -v grep | grep -i"; # Search for a process
    pm = "ps aux --sort=-%mem | head -20"; # Top processes by memory
    pc = "ps aux --sort=-%cpu | head -20"; # Top processes by CPU
    k = "kill"; # Kill process
    k9 = "kill -9"; # Force kill process
    kport = "lsof -ti:"; # Get PID using port (usage: kport 3000)
    zombie = "ps aux | awk '\$8 ~ /^Z/ { print \$2, \$11 }'"; # Find zombie processes
    ports = "lsof -iTCP -sTCP:LISTEN -n -P"; # Show listening ports
    port = "lsof -i"; # Show network connections

    # Disk & storage
    df = "df -h"; # Disk free, human readable
    dus = "du -sh * | sort -h"; # Directory sizes, sorted
    duf = "du -sh ."; # Total size of current directory
    big = "find . -type f -exec ls -lh {} + 2>/dev/null | sort -k5 -hr | head -20"; # Find largest files

    # Network
    myip = "curl -s https://ipinfo.io/ip"; # Get public IP
    localip = "ipconfig getifaddr en0"; # Get local IP
    flushdns = "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"; # Flush DNS cache
    ping = "ping -c 5"; # Ping 5 times default
    speedtest = "curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -"; # Network speed test

    # System info & maintenance
    path = "echo -e \${PATH//:/\\\\n}"; # Print PATH entries on new lines
    paths = "echo -e \${PATH//:/\\\\n} | nl"; # PATH with line numbers
    pathls = "ls -la \$(echo \$PATH | tr ':' ' ')"; # List all dirs in PATH
    services = "launchctl list | grep -v '^-' | sort -k3"; # Active launchd services (sorted)
    update = "brew update && brew upgrade"; # Update system packages
    c = "clear"; # Clear terminal screen
    topmem = "top -l 1 -o rsize -n 10"; # Top 10 processes by memory (macOS native)
    topcpu = "top -l 1 -o cpu -n 10"; # Top 10 processes by CPU (macOS native)
    spotlight = "sudo mdutil"; # Control Spotlight indexing (usage: spotlight -E /)
    quarantine = "xattr -d com.apple.quarantine"; # Remove quarantine attribute from downloads

    # Log analysis (macOS unified logging)
    syslog = "log show --last 1h --info --debug --style compact"; # Recent system logs
    errlog = "log show --last 24h --predicate 'messageType == 16' --info"; # Error logs last 24h
    logstream = "log stream --level info"; # Stream live system logs

    # File permissions & security
    cx = "chmod +x"; # Make executable
    cread = "chmod 644"; # Standard file permissions (read)
    cexec = "chmod 755"; # Standard dir/script permissions (exec)
    own = "sudo chown -R $(whoami)"; # Take ownership recursively
    writable = "find . -type f -perm -002 -ls 2>/dev/null"; # Find world-writable files
    suid = "find /usr /bin /sbin -type f \\( -perm -4000 -o -perm -2000 \\) -ls 2>/dev/null"; # Find SUID/SGID files

    # Secrets management (unified interface)
    sm = "secrets-manager"; # Secrets manager CLI
    smstat = "secrets-manager status"; # Check secrets system status
    smget = "secrets-manager get"; # Get secret value
    smset = "secrets-manager set"; # Set secret (with prompt)
    smrun = "secrets-manager run"; # Run command with secrets injected
    smenv = "secrets-manager env"; # Run with custom env file

    # 1Password integration
    opsign = "op signin"; # Sign into 1Password
    oplist = "op item list"; # List 1Password items
    opssh = "op item list --categories=ssh-key"; # List SSH keys in 1Password
  };
}
