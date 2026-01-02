#!/usr/bin/env bash

set -euo pipefail

load_config() {
    local config_file="${1:-workspace.yml}"
    
    [[ ! -f "$config_file" ]] && return 1
    
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        eval "export $line"
    done < <(parse_yaml "$config_file")
    
    return 0
}

get_config() {
    local key="$1"
    local default="${2:-}"
    local var_name="CONFIG_${key//./_}"
    local var_value="${!var_name:-$default}"
    echo "$var_value"
}

load_from_config() {
    [[ ! -f "$WORKSPACE_FILE" ]] && return 1
    
    load_config "$WORKSPACE_FILE" || return 1
    
    OUTPUT_DIR=$(get_config "build_output_dir" "build")
    ENGINE=$(get_config "build_engine" "pdflatex")
    BIBTEX=$(get_config "build_bibtex" "biber")
    
    PROJECT_TYPE=$(get_config "project_type" "$TYPE")
    PROJECT_CATEGORY=$(get_config "project_category" "$CATEGORY")
    OVERRIDE_DIR=$(get_config "overrides_components_dir" "configs")
    
    return 0
}

export -f load_config get_config load_from_config