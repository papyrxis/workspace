#!/usr/bin/env bash

set -euo pipefail

_PX_LOADER_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$_PX_LOADER_DIR/parser.sh"

load_config() {
    local config_file="${1:-workspace.yml}"
    local records key encoded value

    [[ -f "$config_file" ]] || {
        printf 'Workspace config not found: %s\n' "$config_file" >&2
        return 1
    }

    records="$(parse_yaml "$config_file")" || return 1

    while IFS=$'\t' read -r key encoded; do
        [[ -n "$key" ]] || continue
        [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || {
            printf 'Rejected invalid config variable: %s\n' "$key" >&2
            return 1
        }
        [[ "$encoded" =~ ^[A-Za-z0-9+/]*={0,2}$ ]] || {
            printf 'Rejected malformed base64 value for %s\n' "$key" >&2
            return 1
        }

        if value="$(printf '%s' "$encoded" | base64 --decode 2>/dev/null)"; then
            :
        elif value="$(printf '%s' "$encoded" | base64 -D 2>/dev/null)"; then
            :
        else
            printf 'Could not decode YAML value for %s\n' "$key" >&2
            return 1
        fi

        printf -v "$key" '%s' "$value"
        export "$key"
    done <<< "$records"
}

get_config() {
    local key="$1"
    local default="${2:-}"
    local var_name="CONFIG_${key//./_}"
    var_name="${var_name//-/_}"

    if [[ -v "$var_name" ]]; then
        printf '%s\n' "${!var_name}"
    else
        printf '%s\n' "$default"
    fi
}

load_from_config() {
    [[ -f "$WORKSPACE_FILE" ]] || return 1
    load_config "$WORKSPACE_FILE" || return 1

    OUTPUT_DIR="$(get_config "build_output_dir" "build")"
    ENGINE="$(get_config "build_engine" "xelatex")"
    BIBTEX="$(get_config "build_bibtex" "biber")"
    TYPE="${TYPE:-$(get_config "project_type" "book")}"
    PROJECT_TYPE="$TYPE"
    OVERRIDE_DIR="$(get_config "overrides_dir" "configs")"
    SOURCE="${SOURCE:-$(get_config "build_source" "main.tex")}"
    return 0
}

export -f load_config get_config load_from_config
