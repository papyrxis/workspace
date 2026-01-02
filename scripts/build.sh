#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

VERSION="${VERSION:-$(git describe --tags --always --dirty 2>/dev/null || echo "dev")}"
BUILD_DATE="${BUILD_DATE:-$(date -u '+%Y-%m-%d_%H:%M:%S')}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS] <source.tex>

Build LaTeX document with proper dependency handling.

OPTIONS:
    -o, --output DIR     Output directory (default: build/)
    -e, --engine ENGINE  LaTeX engine: pdflatex|xelatex|lualatex (default: pdflatex)
    -b, --bibtex TOOL    Bibliography tool: biber|bibtex (default: biber)
    -c, --clean          Clean build directory before building
    -w, --watch          Watch mode: rebuild on file changes
    -h, --help           Show this help

EXAMPLES:
    $0 main.tex
    $0 -e xelatex -c main.tex
    $0 --watch main.tex
EOF
}

OUTPUT_DIR="build"
ENGINE="pdflatex"
BIBTEX="biber"
CLEAN=false
WATCH=false
SOURCE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -e|--engine)
            ENGINE="$2"
            shift 2
            ;;
        -b|--bibtex)
            BIBTEX="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -w|--watch)
            WATCH=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ -z "$SOURCE" ]]; then
                SOURCE="$1"
            else
                error "Unknown option: $1"
            fi
            shift
            ;;
    esac
done

[[ -z "$SOURCE" ]] && error "No source file specified"
[[ ! -f "$SOURCE" ]] && error "Source file not found: $SOURCE"

BASENAME="${SOURCE%.tex}"
PDF_NAME="${BASENAME}.pdf"

build_document() {
    log "Building $SOURCE with $ENGINE..."
    
    mkdir -p "$OUTPUT_DIR"
    
    if $CLEAN; then
        log "Cleaning build directory..."
        rm -rf "${OUTPUT_DIR:?}"/*
    fi
    
    export TEXINPUTS=".:${PROJECT_ROOT}:"
    
    log "First pass..."
    $ENGINE -output-directory="$OUTPUT_DIR" -interaction=nonstopmode "$SOURCE" || true
    
    if grep -q '\\bibliography' "$SOURCE" || grep -q '\\addbibresource' "$SOURCE"; then
        log "Running $BIBTEX..."
        (cd "$OUTPUT_DIR" && $BIBTEX "$BASENAME") || true
    fi
    
    log "Second pass..."
    $ENGINE -output-directory="$OUTPUT_DIR" -interaction=nonstopmode "$SOURCE" || true
    
    log "Third pass..."
    $ENGINE -output-directory="$OUTPUT_DIR" -interaction=nonstopmode "$SOURCE"
    
    if [[ -f "$OUTPUT_DIR/$PDF_NAME" ]]; then
        log "Success! Output: $OUTPUT_DIR/$PDF_NAME"
        log "Version: $VERSION"
        log "Build date: $BUILD_DATE"
    else
        error "Build failed"
    fi
}

watch_mode() {
    log "Entering watch mode..."
    build_document
    
    if command -v inotifywait >/dev/null 2>&1; then
        while true; do
            inotifywait -e modify -r . --exclude '\.git|build/' 2>/dev/null
            log "Change detected, rebuilding..."
            build_document
        done
    else
        log "inotifywait not found, falling back to polling..."
        LAST_HASH=$(find . -type f -name "*.tex" -exec md5sum {} \; 2>/dev/null | md5sum)
        while true; do
            sleep 2
            CURRENT_HASH=$(find . -type f -name "*.tex" -exec md5sum {} \; 2>/dev/null | md5sum)
            if [[ "$CURRENT_HASH" != "$LAST_HASH" ]]; then
                log "Change detected, rebuilding..."
                build_document
                LAST_HASH="$CURRENT_HASH"
            fi
        done
    fi
}

if $WATCH; then
    watch_mode
else
    build_document
fi