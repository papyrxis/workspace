#!/usr/bin/env bash

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $*" >&2
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $*" >&2
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $*" >&2
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Simple YAML parser for workspace.yml
parse_yaml() {
    local file="$1"
    local prefix="${2:-CONFIG_}"
    
    [[ ! -f "$file" ]] && return 1
    
    python3 -c "
import yaml
import sys

def flatten_dict(d, parent_key='', sep='_'):
    items = []
    for k, v in d.items():
        new_key = f'{parent_key}{sep}{k}' if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        elif isinstance(v, list):
            items.append((new_key, ' '.join(str(x) for x in v)))
        else:
            items.append((new_key, str(v)))
    return dict(items)

try:
    with open('$file') as f:
        data = yaml.safe_load(f)
    flat = flatten_dict(data)
    for k, v in flat.items():
        # Escape special characters
        v = v.replace('\"', '\\\"').replace('\$', '\\\$')
        print(f'${prefix}{k}=\"{v}\"')
except Exception as e:
    print(f'# Error parsing YAML: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null || {
        # Fallback to basic parsing if Python not available
        local s='[[:space:]]*'
        local w='[a-zA-Z0-9_]*'
        local fs=$(echo @|tr @ '\034')
        
        sed -ne "s|^\($s\):|\1|" \
             -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
             -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$file" |
        awk -F"$fs" '{
            indent = length($1)/2;
            vname[indent] = $2;
            for (i in vname) {if (i > indent) {delete vname[i]}}
            if (length($3) > 0) {
                vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
                printf("%s%s%s=\"%s\"\n", "'"$prefix"'",vn, $2, $3);
            }
        }'
    }
}

# Load configuration from workspace.yml
load_config() {
    local config_file="${1:-workspace.yml}"
    
    [[ ! -f "$config_file" ]] && return 1
    
    # Parse and export variables
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue  # Skip comments
        [[ -z "$line" ]] && continue
        eval "export $line"
    done < <(parse_yaml "$config_file")
    
    return 0
}

# Get config value with fallback
get_config() {
    local key="$1"
    local default="${2:-}"
    local var_name="CONFIG_${key//./_}"
    echo "${!var_name:-$default}"
}

# Get version from git or config
get_version() {
    local version_source=$(get_config "version_source" "git")
    local fallback=$(get_config "version_fallback" "dev")
    
    if [[ "$version_source" == "git" ]] && command_exists git && git rev-parse --git-dir > /dev/null 2>&1; then
        git describe --tags --always --dirty 2>/dev/null || echo "$fallback"
    else
        echo "$fallback"
    fi
}

# Get build date
get_build_date() {
    date -u '+%Y-%m-%d %H:%M:%S UTC'
}

# Find workspace root
find_workspace_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/common" ]] && [[ -d "$dir/scripts" ]]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

# Create directory if not exists
ensure_dir() {
    local dir="$1"
    [[ ! -d "$dir" ]] && mkdir -p "$dir"
    return 0
}

# Check LaTeX installation
check_latex() {
    local engine="${1:-pdflatex}"
    
    if ! command_exists "$engine"; then
        error "LaTeX engine '$engine' not found. Install TeX Live or MiKTeX."
    fi
}

# Check bibtex tool
check_bibtex() {
    local tool="${1:-biber}"
    
    if ! command_exists "$tool"; then
        warn "Bibliography tool '$tool' not found. Bibliography may not work."
        return 1
    fi
    return 0
}

# Format pad number
pad_number() {
    printf "%02d" "$1"
}

# Copyright generator with proper mappings
generate_copyright_text() {
    local type=$(get_config "copyright_type" "cc-by-sa")
    local year=$(get_config "copyright_year" "auto")
    local holder=$(get_config "copyright_holder" "Author Name")
    local custom=$(get_config "copyright_custom_text" "")
    
    [[ "$year" == "auto" ]] && year=$(date +%Y)
    
    case "$type" in
        cc-by-sa)
            cat <<EOF
Copyright © $year $holder

This work is licensed under the Creative Commons Attribution-ShareAlike 4.0 
International License. To view a copy of this license, visit:
\\url{http://creativecommons.org/licenses/by-sa/4.0/}
EOF
            ;;
        cc-by)
            cat <<EOF
Copyright © $year $holder

This work is licensed under the Creative Commons Attribution 4.0 
International License. To view a copy of this license, visit:
\\url{http://creativecommons.org/licenses/by/4.0/}
EOF
            ;;
        cc-by-nc)
            cat <<EOF
Copyright © $year $holder

This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 
International License. To view a copy of this license, visit:
\\url{http://creativecommons.org/licenses/by-nc/4.0/}
EOF
            ;;
        cc-by-nc-sa)
            cat <<EOF
Copyright © $year $holder

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 
International License. To view a copy of this license, visit:
\\url{http://creativecommons.org/licenses/by-nc-sa/4.0/}
EOF
            ;;
        mit)
            cat <<EOF
Copyright © $year $holder

Permission is hereby granted, free of charge, to any person obtaining a copy
of this document, to deal in the document without restriction, including without 
limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies, and to permit persons to whom the document is furnished to do so, 
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the document.
EOF
            ;;
        apache)
            cat <<EOF
Copyright © $year $holder

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at:
\\url{http://www.apache.org/licenses/LICENSE-2.0}
EOF
            ;;
        custom)
            if [[ -n "$custom" ]]; then
                echo "$custom"
            else
                echo "Copyright © $year $holder. All rights reserved."
            fi
            ;;
        none)
            echo ""
            ;;
        *)
            echo "Copyright © $year $holder. All rights reserved."
            ;;
    esac
}

# Check if Python 3 with PyYAML is available
check_yaml_parser() {
    if command_exists python3; then
        python3 -c "import yaml" 2>/dev/null && return 0
    fi
    return 1
}

# Export functions for use in other scripts
export -f log warn error info
export -f command_exists parse_yaml get_config load_config
export -f get_version get_build_date find_workspace_root
export -f ensure_dir check_latex check_bibtex check_yaml_parser
export -f pad_number generate_copyright_text