#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}

usage() {
    cat <<EOF
Usage: $0 <chapter.tex>

Build a single chapter independently.

EXAMPLE:
    $0 parts/part01/chapter01/chapter01.tex
EOF
}

[[ $# -eq 0 ]] && { usage; exit 1; }

CHAPTER_FILE="$1"
[[ ! -f "$CHAPTER_FILE" ]] && error "Chapter file not found: $CHAPTER_FILE"

CHAPTER_DIR="$(dirname "$CHAPTER_FILE")"
CHAPTER_NAME="$(basename "$CHAPTER_FILE" .tex)"

log "Building chapter: $CHAPTER_NAME"

TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

cat > "$TMP_DIR/wrapper.tex" <<EOF
\documentclass[12pt,oneside]{book}
\input{common/presets/book/technical}
\begin{document}
\input{$CHAPTER_FILE}
\end{document}
EOF

cd "$TMP_DIR"
export TEXINPUTS=".:${WORKSPACE_ROOT}:"

pdflatex -interaction=nonstopmode wrapper.tex >/dev/null
pdflatex -interaction=nonstopmode wrapper.tex

[[ -f wrapper.pdf ]] && cp wrapper.pdf "${WORKSPACE_ROOT}/${CHAPTER_NAME}.pdf"

log "Success: ${CHAPTER_NAME}.pdf"