#!/usr/bin/env bash

set -euo pipefail

parse_yaml() {
    local file="$1"
    local prefix="${2:-CONFIG_}"
    
    [[ ! -f "$file" ]] && return 1
    
    if command_exists python3 && python3 -c "import yaml" 2>/dev/null; then
        parse_yaml_python "$file" "$prefix"
    else
        parse_yaml_fallback "$file" "$prefix"
    fi
}

parse_yaml_python() {
    local file="$1"
    local prefix="$2"
    
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
        v = v.replace('\"', '\\\"').replace('\$', '\\\$')
        print(f'${prefix}{k}=\"{v}\"')
except Exception as e:
    print(f'# Error parsing YAML: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null
}

parse_yaml_fallback() {
    local file="$1"
    local prefix="$2"
    
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

export -f parse_yaml parse_yaml_python parse_yaml_fallback