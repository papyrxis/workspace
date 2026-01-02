#!/usr/bin/env bash

set -euo pipefail

get_version() {
    local version_source="${CONFIG_version_source:-git}"
    local fallback="${CONFIG_version_fallback:-dev}"
    
    if [[ "$version_source" == "git" ]] && command_exists git && git rev-parse --git-dir >/dev/null 2>&1; then
        local version
        version=$(git describe --tags --always --dirty 2>/dev/null)
        if [[ -n "$version" ]]; then
            echo "$version"
        else
            echo "$fallback"
        fi
    else
        echo "$fallback"
    fi
}

detect_git_info() {
    if ! command_exists git || ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 0
    fi
    
    if [[ -z "$AUTHOR" ]]; then
        AUTHOR=$(git config user.name 2>/dev/null || echo "")
    fi
    
    if [[ -z "$EMAIL" ]]; then
        EMAIL=$(git config user.email 2>/dev/null || echo "")
    fi
    
    if [[ -z "$URL" ]]; then
        local remote
        remote=$(git config --get remote.origin.url 2>/dev/null || echo "")
        if [[ -n "$remote" ]]; then
            if [[ "$remote" =~ ^git@ ]]; then
                URL=$(echo "$remote" | sed 's|git@\(.*\):\(.*\)\.git|https://\1/\2|')
            else
                URL="${remote%.git}"
            fi
        fi
    fi
}

get_git_tag() {
    if command_exists git && git rev-parse --git-dir >/dev/null 2>&1; then
        git describe --tags --abbrev=0 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

get_git_commit() {
    if command_exists git && git rev-parse --git-dir >/dev/null 2>&1; then
        git rev-parse HEAD 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

check_git_dirty() {
    if command_exists git && git rev-parse --git-dir >/dev/null 2>&1; then
        git diff-index --quiet HEAD -- 2>/dev/null
        return $?
    fi
    return 1
}

export -f get_version detect_git_info get_git_tag get_git_commit check_git_dirty