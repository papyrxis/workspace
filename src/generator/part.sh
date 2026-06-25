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

    success "Created: $PART_DIR/part${PADDED_PART}.tex"
    info ""
    info "Add to main.tex:"
    info "  \\input{$PART_DIR/part${PADDED_PART}}"
    info ""
    info "Then add chapters:"
    info "  make chapter ARGS='-p $PART -c 1 -t \"Chapter Title\"'"
}

generate_part_file() {
    local part_file="$PART_DIR/part${PADDED_PART}.tex"

    cat > "$part_file" <<EOF
\\part{$TITLE}
\\label{part:part${PADDED_PART}}

\\begin{partintro}
$(if [[ -n "$DESCRIPTION" ]]; then echo "$DESCRIPTION"
  else echo "An overview of what this part covers."; fi)

\\vspace{1em}

\\textbf{Chapters in this part:}
\\begin{itemize}
\\item Chapter 1: ...
\\end{itemize}
\\end{partintro}
EOF
}

main "$@"
