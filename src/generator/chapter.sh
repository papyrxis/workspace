#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"

source "$SCRIPT_DIR/context.sh"
source "$SCRIPT_DIR/utils/logger.sh"
source "$SCRIPT_DIR/utils/utils.sh"
source "$SCRIPT_DIR/utils/messages_builder.sh"
source "$SCRIPT_DIR/args.sh"
source "$SCRIPT_DIR/bootstrap.sh"
source "$SCRIPT_DIR/checker.sh"

main() {
    bootstrap_paths
    
    parse_chapter_args "$@"
    
    derive_context
    validate_chapter_context
    
    log "Creating chapter $PART.$CHAPTER: $TITLE"
    
    ensure_dir "$CHAPTER_DIR"
    ensure_dir "$CHAPTER_DIR/figures"
    
    generate_chapter_file
    
    success "Created: $CHAPTER_FILE"
    info ""
    info "Next steps:"
    info "  1. Add to $PART_DIR/part$PADDED_PART.tex after \\end{partintro}:"
    info "     \\input{$CHAPTER_FILE}"
    info "  2. Edit chapter content: $CHAPTER_FILE"
    info "  3. Add figures to: $CHAPTER_DIR/figures/"
}

generate_chapter_file() {
    cat > "$CHAPTER_FILE" <<EOF
\\chapter{$TITLE}
\\label{ch:chapter$PADDED_CHAPTER}

\\begin{chapterintro}
$(if [[ -n "$DESCRIPTION" ]]; then
    echo "$DESCRIPTION"
else
    echo "Introduction to this chapter. What will be covered and why it matters."
fi)
\\end{chapterintro}

EOF

    if [[ -n "$SECTIONS" ]]; then
        generate_custom_sections
    else
        generate_default_sections
    fi
    
    cat >> "$CHAPTER_FILE" <<EOF

\\section{Summary}

Chapter summary and key takeaways.

\\begin{keyidea}
The main idea of this chapter is...
\\end{keyidea}
EOF
}

generate_custom_sections() {
    IFS=',' read -ra SECTION_ARRAY <<< "$SECTIONS"
    for section in "${SECTION_ARRAY[@]}"; do
        section=$(echo "$section" | xargs)
        cat >> "$CHAPTER_FILE" <<SECTION

\\section{$section}

Content for $section.

SECTION
    done
}

generate_default_sections() {
    cat >> "$CHAPTER_FILE" <<'EOF'

\section{Introduction}

Opening section.

\section{Main Content}

Core material.

\subsection{Details}

Detailed explanation.

\section{Examples}

Concrete examples.

\begin{example}
Example content here.
\end{example}
EOF
}

main "$@"