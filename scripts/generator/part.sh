#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$WORKSPACE_ROOT/scripts/common.sh"

usage() {
    cat <<EOF
Usage: $0 -n NUMBER -t TITLE [-d DESCRIPTION]

Generate a new part structure for a book.

OPTIONS:
    -n, --number NUM      Part number (1, 2, 3, ...)
    -t, --title TITLE     Part title
    -d, --desc TEXT       Part description (optional)
    -h, --help           Show this help

EXAMPLE:
    $0 -n 2 -t "Advanced Topics" -d "Deep dive into advanced concepts"

NOTES:
    - Creates parts/partNN/ directory
    - Generates partNN.tex with proper structure
    - Updates main.tex (manual step)

EOF
}

NUM=""
TITLE=""
DESCRIPTION=""

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
        -d|--desc)
            DESCRIPTION="$2"
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

PADDED_NUM=$(pad_number "$NUM")
PART_DIR="parts/part$PADDED_NUM"
PART_FILE="$PART_DIR/part$PADDED_NUM.tex"

[[ -d "$PART_DIR" ]] && error "Part already exists: $PART_DIR"

log "Creating part $NUM: $TITLE"
ensure_dir "$PART_DIR"

# Generate part file
cat > "$PART_FILE" <<EOF
\\part{$TITLE}
\\label{part:part$PADDED_NUM}

\\begin{partintro}
\\lettrine[lines=3]{T}{his} is Part $NUM of the book.

$(if [[ -n "$DESCRIPTION" ]]; then
    echo "$DESCRIPTION"
else
    echo "Overview of what this part covers and why it matters."
fi)

\\vspace{1em}

\\textbf{In this part:}
\\begin{itemize}
\\item Chapter 1: Introduction
\\item Chapter 2: Main concepts
\\item Chapter 3: Advanced topics
\\end{itemize}
\\end{partintro}
EOF

log "Created: $PART_FILE"
info ""
info "Next steps:"
info "  1. Add to main.tex:"
info "     \\input{$PART_FILE}"
info "  2. Generate chapters:"
info "     bash scripts/generate/gen-chapter.sh -p $NUM -c 1 -t \"Chapter Title\""