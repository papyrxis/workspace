#!/usr/bin/env bash

set -euo pipefail

check_latex() {
    local engine="${1:-pdflatex}"
    
    if ! command_exists "$engine"; then
        error "LaTeX engine '$engine' not found. Install TeX Live or MiKTeX."
    fi
    return 0
}

check_bibtex() {
    local tool="${1:-biber}"
    
    if ! command_exists "$tool"; then
        warn "Bibliography tool '$tool' not found. Bibliography may not work."
        return 1
    fi
    return 0
}

check_yaml_parser() {
    if command_exists python3 && python3 -c "import yaml" 2>/dev/null; then
        return 0
    fi
    return 1
}

check_watch_tool() {
    if command_exists inotifywait; then
        echo "inotifywait"
        return 0
    elif command_exists fswatch; then
        echo "fswatch"
        return 0
    else
        echo "polling"
        return 0
    fi
}

check_git() {
    command_exists git && git rev-parse --git-dir >/dev/null 2>&1
}

check_file_exists() {
    local file="$1"
    [[ -f "$file" ]]
}

check_dir_exists() {
    local dir="$1"
    [[ -d "$dir" ]]
}

check_workspace_file() {
    [[ -f "$WORKSPACE_FILE" ]]
}

check_component_exists() {
    local component="$1"
    local component_path="$WORKSPACE_ROOT/common/components/${component}.tex"
    [[ -f "$component_path" ]]
}

check_package_exists() {
    local package="$1"
    local package_path="$WORKSPACE_ROOT/common/packages/${package}.tex"
    [[ -f "$package_path" ]]
}

check_override_allowed() {
    local component="$1"
    local allowed="${CONFIG_overrides_allow:-}"
    [[ " $allowed " == *" $component "* ]]
}

export -f check_latex check_bibtex check_yaml_parser check_watch_tool
export -f check_git check_file_exists check_dir_exists check_workspace_file
export -f check_component_exists check_package_exists check_override_allowed