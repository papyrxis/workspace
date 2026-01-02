#!/usr/bin/env bash

set -euo pipefail

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}

usage() {
    cat <<EOF
Usage: $0 -n NUM -t TITLE

Create new part structure.

OPTIONS:
    -n, --number NUM   Part number (1, 2, 3, ...)
    -t, --title TITLE  Part title
    -h, --help         Show this help

EXAMPLE:
    $0 -n 2 -t "Advanced Topics"
EOF
}

NUM=""
TITLE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--number)
            NUM="$2"
            shift 2
            ;;
        -t|--title)
            TITLE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

[[ -z "$NUM" ]] && error "Part number required (-n)"
[[ -z "$TITLE" ]] && error "Part title required (-t)"

PART_DIR="parts/part$(printf '%02d' "$NUM")"
PART_FILE="${PART_DIR}/part$(printf '%02d' "$NUM").tex"

[[ -d "$PART_DIR" ]] && error "Part already exists: $PART_DIR"

log "Creating part: $TITLE"
mkdir -p "$PART_DIR"

cat > "$PART_FILE" <<EOF
\\part{$TITLE}
\\label{part:part$(printf '%02d' "$NUM")}

\\begin{partintro}
\\lettrine[lines=3]{I}{ntroduction} to this part.

Overview of what this part covers and why it matters.
\\end{partintro}
EOF

log "Created: $PART_FILE"
log "Add to main.tex:"
log "  \\input{$PART_FILE}"