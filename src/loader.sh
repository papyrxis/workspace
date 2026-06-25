#!/usr/bin/env bash

set -euo pipefail

load_config() {
    local config_file="${1:-workspace.yml}"

    [[ ! -f "$config_file" ]] && return 1

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
    var_name="${var_name//-/_}"

    if [[ -v "$var_name" ]]; then
        echo "${!var_name}"
    else
        echo "$default"
    fi
}

load_from_config() {
    [[ ! -f "$WORKSPACE_FILE" ]] && return 1

    load_config "$WORKSPACE_FILE" || return 1

    OUTPUT_DIR=$(get_config "build_output_dir" "build")
    ENGINE=$(get_config "build_engine" "pdflatex")
    BIBTEX=$(get_config "build_bibtex" "biber")

    [[ -z "$TYPE" ]] && TYPE=$(get_config "project_type" "book")

    PROJECT_TYPE="$TYPE"
    OVERRIDE_DIR=$(get_config "overrides_dir" "configs")

    # SOURCE: from config if not set already
    if [[ -z "$SOURCE" ]]; then
        local cfg_source
        cfg_source=$(get_config "build_source" "main.tex")
        SOURCE="$cfg_source"
    fi

    return 0
}

export -f load_config get_config load_from_config
