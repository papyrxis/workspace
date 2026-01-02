#!/usr/bin/env bash

set -euo pipefail

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

ensure_dir() {
    local dir="$1"
    [[ ! -d "$dir" ]] && mkdir -p "$dir"
    return 0
}

pad_number() {
    printf "%02d" "$1"
}

get_build_date() {
    date -u '+%Y-%m-%d %H:%M:%S UTC'
}

find_workspace_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/common" ]] && [[ -d "$dir/src" ]]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

generate_copyright_text() {
    local type="${CONFIG_copyright_type:-cc-by-sa}"
    local year="${CONFIG_copyright_year:-auto}"
    local holder="${CONFIG_copyright_holder:-Author Name}"
    local custom="${CONFIG_copyright_custom_text:-}"
    
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

export -f command_exists ensure_dir pad_number get_build_date
export -f find_workspace_root generate_copyright_text