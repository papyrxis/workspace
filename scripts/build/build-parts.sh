#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}

[[ ! -d "parts" ]] && error "No parts/ directory found"

log "Building all parts..."

for part in parts/part*/; do
    part_num=$(basename "$part")
    log "Building $part_num..."
    
    for chapter in "$part"chapter*/; do
        [[ ! -d "$chapter" ]] && continue
        chapter_file="${chapter}$(basename "$chapter").tex"
        
        if [[ -f "$chapter_file" ]]; then
            log "  - $(basename "$chapter")"
            "${SCRIPT_DIR}/build-chapter.sh" "$chapter_file" || log "    Failed"
        fi
    done
done

log "All parts processed"