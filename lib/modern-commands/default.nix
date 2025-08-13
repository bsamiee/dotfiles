# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Dotfiles
# License       : MIT
# Path          : lib/modern-commands/default.nix
# ---------------------------------------
# Modern command replacement system - generates shell functions for Unix commands

{ lib, pkgs, ... }:

let
  # Generate a modern command replacement function
  mkModernCommand =
    {
      name, # Command name (e.g., "ls")
      baseCommand, # Modern tool to use (e.g., "eza")
      defaultFlags ? [ ], # Default flags always added
      flagMappings ? { }, # Unix flag → modern flag mappings
      contextRules ? [ ], # Context-aware flag additions
      description ? "", # Command description
      _specialHandlers ? { }, # Special handling for complex translations (reserved)
      _unsupportedFeatures ? { }, # Unsupported features with messages (reserved)
      _modernFeatures ? { }, # Modern tool-specific features (reserved)
    }:
    let
      # Convert flag mappings to shell case statement
      flagCases = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (unix: modern: ''
          ${unix})
            modern_flags+=("${modern}")
            ;;
        '') flagMappings
      );

      # Convert context rules to shell conditionals
      contextChecks = lib.concatStringsSep "\n" (
        map (rule: ''
          if ${rule.condition}; then
            context_flags+=(${lib.concatStringsSep " " (map (f: ''"${f}"'') rule.flags)})
          fi
        '') contextRules
      );

      # Default flags as string
      defaultFlagsStr = lib.concatStringsSep " " (map (f: ''"${f}"'') defaultFlags);

    in
    ''
      # ${description}
      ${name}() {
        local -a modern_flags=()
        local -a context_flags=()
        local -a user_args=()
        local skip_next=false
        local has_pattern=false
        local find_pattern=""
        
        ${lib.optionalString (name == "ls") ''
          # Track if we're in long format for ls
          export LS_LONG=false
          for arg in "$@"; do
            if [[ "$arg" == "-l"* ]] || [[ "$arg" == *"l"* && "$arg" == -* && ! "$arg" == "--"* ]]; then
              export LS_LONG=true
              break
            fi
          done
        ''}

        ${lib.optionalString (name == "find") ''
          # Special handling for find command

          # Helper functions for find-specific translations
          translate_time() {
            local value="$1"
            local num="''${value#[+-]}"
            if [[ "$value" == -* ]]; then
              echo "''${num}d"
            elif [[ "$value" == +* ]]; then
              echo ">''${num}d"
            else
              echo "''${num}d"
            fi
          }

          translate_size() {
            local value="$1"
            if [[ "$value" == +* ]]; then
              echo ">''${value#+}"
            elif [[ "$value" == -* ]]; then
              echo "<''${value#-}"
            else
              echo "$value"
            fi
          }

          translate_type() {
            local value="$1"
            case "$value" in
              f) echo "file" ;;
              d) echo "directory" ;;
              l) echo "symlink" ;;
              p) echo "pipe" ;;
              s) echo "socket" ;;
              x) echo "executable" ;;
              e) echo "empty" ;;
              b) echo "block" ;;
              c) echo "char" ;;
              *) echo "$value" ;;
            esac
          }

          translate_owner() {
            local value="$1"
            # Handle user:group format for --owner
            echo "$value"
          }
        ''}

        # Parse arguments and translate flags
        for arg in "$@"; do
          if [[ "$skip_next" == true ]]; then
            skip_next=false
            ${lib.optionalString (name == "find") ''
              # Special value handling for find
              case "$prev_flag" in
                -type)
                  # Handle multiple types: -type f,d
                  if [[ "$arg" == *,* ]]; then
                    IFS=',' read -ra types <<< "$arg"
                    for t in "''${types[@]}"; do
                      modern_flags+=("--type=$(translate_type "$t")")
                    done
                  else
                    modern_flags+=("--type=$(translate_type "$arg")")
                  fi
                  ;;
                -mtime|-ctime)
                  modern_flags+=("--changed-within=$(translate_time "$arg")")
                  ;;
                -size)
                  modern_flags+=("--size=$(translate_size "$arg")")
                  ;;
                -name|-iname)
                  find_pattern="$arg"
                  has_pattern=true
                  ;;
                -user|-group)
                  modern_flags+=("$(translate_owner "$arg")")
                  ;;
                -owner)
                  modern_flags+=("$arg")  # Already in fd format
                  ;;
                *)
                  user_args+=("$arg")
                  ;;
              esac
            ''}
            ${lib.optionalString (name != "find") ''
              user_args+=("$arg")
            ''}
            continue
          fi

          case "$arg" in
            ${lib.optionalString (name == "find") ''
              # Special flags for find that need values
              -type|-mtime|-ctime|-size|-name|-iname|-maxdepth|-mindepth|-newer|-user|-group|-owner)
                prev_flag="$arg"
                skip_next=true
                case "$arg" in
                  -name)
                    modern_flags+=("--glob")  # Use glob mode for shell patterns
                    ;;
                  -iname)
                    modern_flags+=("--glob" "--ignore-case")
                    ;;
                  -maxdepth)
                    modern_flags+=("--max-depth")
                    ;;
                  -mindepth)
                    modern_flags+=("--min-depth")
                    ;;
                  -user|-group)
                    modern_flags+=("--owner")
                    ;;
                esac
                ;;
              # Handle -exec specially
              -exec|-execdir)
                # Collect all args until \; or +
                local exec_cmd=()
                shift  # Skip -exec itself
                while [[ $# -gt 0 ]] && [[ "$1" != ";" ]] && [[ "$1" != "+" ]]; do
                  exec_cmd+=("$1")
                  shift
                done
                if [[ "$1" == "+" ]]; then
                  modern_flags+=("--exec-batch")
                else
                  modern_flags+=("--exec")
                fi
                modern_flags+=("''${exec_cmd[@]}")
                ;;
              # Handle -delete action
              -delete)
                modern_flags+=("--exec" "rm" "{}")
                ;;
              # Handle logical NOT
              !|-not)
                # This is complex - for now just skip
                ;;
              # Handle paths that look like options but aren't
              -*)
            ''}
            # Combined short flags (e.g., -la)
            -[!-]*)
              if [[ "''${#arg}" -gt 2 ]]; then
                # Split combined flags
                for (( i=1; i<''${#arg}; i++ )); do
                  flag="-''${arg:$i:1}"
                  case "$flag" in
                    ${flagCases}
                    *)
                      modern_flags+=("$flag")
                      ;;
                  esac
                done
              else
                # Single short flag
                case "$arg" in
                  ${flagCases}
                  *)
                    modern_flags+=("$arg")
                    ;;
                esac
              fi
              ;;
            # Long flags or arguments
            *)
              ${lib.optionalString (name == "find") ''
                # For find, non-flag args could be paths or patterns
                if [[ ! "$has_pattern" == true ]] && [[ ! "$arg" == /* ]] && [[ ! -e "$arg" ]]; then
                  # Likely a pattern
                  find_pattern="$arg"
                  has_pattern=true
                else
                  user_args+=("$arg")
                fi
              ''}
              ${lib.optionalString (name != "find") ''
                user_args+=("$arg")
              ''}
              ;;
          esac
        done

        # Apply context rules
        ${contextChecks}

        # Build final command
        local -a final_args=(${defaultFlagsStr})

        # Add context flags
        if [[ ''${#context_flags[@]} -gt 0 ]]; then
          final_args+=("''${context_flags[@]}")
        fi

        # Add translated flags
        if [[ ''${#modern_flags[@]} -gt 0 ]]; then
          final_args+=("''${modern_flags[@]}")
        fi

        ${lib.optionalString (name == "find") ''
          # Add pattern for find command
          if [[ -n "$find_pattern" ]]; then
            final_args+=("$find_pattern")
          fi
        ''}

        # Add user arguments (paths, etc.)
        if [[ ''${#user_args[@]} -gt 0 ]]; then
          final_args+=("''${user_args[@]}")
        fi

        # Execute modern command
        command ${baseCommand} "''${final_args[@]}"
      }
    '';

  # Import all command configurations
  commands = {
    ls = import ./commands/ls.nix { inherit lib pkgs; };
    find = import ./commands/find.nix { inherit lib pkgs; };
  };

  # Generate all command functions
  generatedFunctions = lib.mapAttrs (
    name: config: mkModernCommand (config // { inherit name; })
  ) commands;

in
{
  inherit mkModernCommand generatedFunctions;

  # Generate a single shell script with all functions
  shellFunctions = lib.concatStringsSep "\n\n" (lib.attrValues generatedFunctions);
}
