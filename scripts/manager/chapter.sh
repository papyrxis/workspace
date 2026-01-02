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
Usage: $0 -p PART -c CHAPTER -t TITLE

Create new chapter structure.

OPTIONS:
    -p, --part NUM      Part number (1, 2, 3, ...)
    -c, --chapter NUM   Chapter number (1, 2, 3, ...)
    -t, --title TITLE   Chapter title
    -h, --help          Show this help

EXAMPLE:
    $0 -p 1 -c 3 -t "New Chapter"
EOF
}

PART=""
CHAPTER=""
TITLE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--part)
            PART="$2"
            shift 2
            ;;
        -c|--chapter)
            CHAPTER="$2"
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

[[ -z "$PART" ]] && error "Part number required (-p)"
[[ -z "$CHAPTER" ]] && error "Chapter number required (-c)"
[[ -z "$TITLE" ]] && error "Chapter title required (-t)"

PART_DIR="parts/part$(printf '%02d' "$PART")"
CHAPTER_DIR="${PART_DIR}/chapter$(printf '%02d' "$CHAPTER")"
CHAPTER_FILE="${CHAPTER_DIR}/chapter$(printf '%02d' "$CHAPTER").tex"

[[ -d "$CHAPTER_DIR" ]] && error "Chapter already exists: $CHAPTER_DIR"

log "Creating chapter: $TITLE"
mkdir -p "$CHAPTER_DIR"

cat > "$CHAPTER_FILE" <<EOF
\\chapter{$TITLE}
\\label{ch:chapter$(printf '%02d' "$CHAPTER")}

\\begin{chapterintro}
Introduction to this chapter.
\\end{chapterintro}

\\section{First Section}

Content here.

\\section{Second Section}

More content.

\\section{Summary}

Chapter summary.
EOF

log "Created: $CHAPTER_FILE"
log "Add to main.tex:"
log "  \\input{$CHAPTER_FILE}"