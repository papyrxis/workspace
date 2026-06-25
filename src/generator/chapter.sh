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
    info "Add to $PART_DIR/part${PADDED_PART}.tex:"
    info "  \\input{$CHAPTER_FILE}"
}

generate_chapter_file() {
    cat > "$CHAPTER_FILE" <<EOF
\\chapter{$TITLE}
\\label{ch:chapter${PADDED_CHAPTER}}

\\begin{chapterintro}
$(if [[ -n "$DESCRIPTION" ]]; then echo "$DESCRIPTION"
  else echo "What this chapter is about and why it matters."; fi)
\\end{chapterintro}

EOF

    if [[ -n "$SECTIONS" ]]; then
        IFS=',' read -ra SARR <<< "$SECTIONS"
        for s in "${SARR[@]}"; do
            s=$(echo "$s" | xargs)
            cat >> "$CHAPTER_FILE" <<SECTION

\\section{$s}

Content.

SECTION
        done
    else
        cat >> "$CHAPTER_FILE" <<'BODY'

\section{Introduction}

Opening thoughts.

\section{Core Concepts}

The main ideas.

\subsection{Detail}

Deeper explanation.

\section{Example}

\begin{example}
Example content here.
\end{example}

\section{Summary}

Key takeaways.

\begin{keyidea}
The main idea of this chapter.
\end{keyidea}
BODY
    fi
}

main "$@"
