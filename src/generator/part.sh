#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"

source "$SCRIPT_DIR/context.sh"
source "$SCRIPT_DIR/utils/logger.sh"
source "$SCRIPT_DIR/utils/utils.sh"
source "$SCRIPT_DIR/utils/messages_builder.sh"
source "$SCRIPT_DIR/args.sh"
source "$SCRIPT_DIR/bootstrap.sh"

main() {
    bootstrap_paths
    
    parse_part_args "$@"
    
    derive_context
    validate_part_context
    
    check_dir_exists "$PART_DIR" && error "Part already exists: $PART_DIR"
    
    log "Creating part $PART: $TITLE"
    
    ensure_dir "$PART_DIR"
    
    generate_part_file
    
    success "Created: $PART_DIR/part$PADDED_PART.tex"
    info ""
    info "Next steps:"
    info "  1. Add to main.tex:"
    info "     \\input{$PART_DIR/part$PADDED_PART}"
    info "  2. Generate chapters:"
    info "     bash workspace/src/generator/chapter.sh -p $PART -c 1 -t \"Chapter Title\""
}

generate_part_file() {
    local part_file="$PART_DIR/part$PADDED_PART.tex"
    
    cat > "$part_file" <<EOF
\\part{$TITLE}
\\label{part:part$PADDED_PART}

\\begin{partintro}
\\lettrine[lines=3]{T}{his} is Part $PART of the book.

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
}

main "$@"