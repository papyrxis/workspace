#!/usr/bin/env bash

set -euo pipefail

check_latex() {
    local engine="${1:-pdflatex}"
    command_exists "$engine" || error "LaTeX engine '$engine' not found. Install TeX Live or MiKTeX."
    return 0
}

check_bibtex() {
    local tool="${1:-biber}"
    command_exists "$tool" || { warn "Bibliography tool '$tool' not found. Bibliography may not work."; return 1; }
    return 0
}

check_watch_tool() {
    if command_exists inotifywait; then echo "inotifywait"
    elif command_exists fswatch;   then echo "fswatch"
    else                                echo "polling"
    fi
}

check_git() {
    command_exists git && git rev-parse --git-dir >/dev/null 2>&1
}

check_file_exists()  { [[ -f "$1" ]]; }
check_dir_exists()   { [[ -d "$1" ]]; }
check_workspace_file() { [[ -f "$WORKSPACE_FILE" ]]; }

# Check if a component exists in common/components/
check_component_exists() {
    [[ -f "$WORKSPACE_ROOT/common/components/${1}.tex" ]]
}

# Check if a package exists in common/packages/
check_package_exists() {
    [[ -f "$WORKSPACE_ROOT/common/packages/${1}.tex" ]]
}

# Check if an override file exists in the user's override dir
check_override_exists() {
    local component="$1"   # e.g. "colors" or "commands/base"
    local override_dir="${OVERRIDE_DIR:-configs}"
    [[ -f "$override_dir/${component}.tex" ]]
}

export -f check_latex check_bibtex check_watch_tool
export -f check_git check_file_exists check_dir_exists check_workspace_file
export -f check_component_exists check_package_exists check_override_exists
