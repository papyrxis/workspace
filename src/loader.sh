#!/usr/bin/env bash

set -euo pipefail

load_config() {
    local config_file="${1:-workspace.yml}"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        
        if [[ "$line" == *"="* ]]; then
            local key="${line%%=*}"
            local value="${line#*=}"
            
            if [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
                eval "export ${key}=${value}"
            fi
        fi
    done < <(parse_yaml "$config_file" 2>/dev/null)
    
    return 0
}

get_config() {
    local key="$1"
    local default="${2:-}"
    local var_name="CONFIG_${key//./_}"
    local var_name="${var_name//-/_}"
    
    if [[ -v "$var_name" ]]; then
        local value="${!var_name}"
        echo "$value"
    else
        echo "$default"
    fi
}

load_from_config() {
    if [[ ! -f "$WORKSPACE_FILE" ]]; then
        return 1
    fi
    
    if ! load_config "$WORKSPACE_FILE"; then
        return 1
    fi
    
    OUTPUT_DIR=$(get_config "build_output_dir" "build")
    ENGINE=$(get_config "build_engine" "pdflatex")
    BIBTEX=$(get_config "build_bibtex" "biber")
    
    [[ -z "$TYPE" ]] && TYPE=$(get_config "project_type" "book")
    [[ -z "$CATEGORY" ]] && CATEGORY=$(get_config "project_category" "technical")
    
    PROJECT_TYPE="$TYPE"
    PROJECT_CATEGORY="$CATEGORY"
    OVERRIDE_DIR=$(get_config "overrides_components_dir" "configs")
    
    return 0
}

export -f load_config get_config load_from_config