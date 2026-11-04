#!/usr/bin/env bash

set -euo pipefail

# YAML is parsed by Python and emitted as base64 records. Shell values are never
# evaluated as source code.
parse_yaml() {
    local file="$1"
    local prefix="${2:-CONFIG_}"
    local script_dir

    [[ -f "$file" ]] || {
        printf 'YAML file not found: %s\n' "$file" >&2
        return 1
    }
    command -v python3 >/dev/null 2>&1 || {
        printf 'python3 is required to parse workspace.yml safely\n' >&2
        return 127
    }
    python3 -c 'import yaml' >/dev/null 2>&1 || {
        printf 'PyYAML is required; install Workspace dependencies first\n' >&2
        return 127
    }

    script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    python3 "$script_dir/parser.py" "$file" "$prefix"
}

export -f parse_yaml
