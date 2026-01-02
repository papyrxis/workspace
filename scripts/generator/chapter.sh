#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$WORKSPACE_ROOT/scripts/common.sh"

usage() {
    cat <<EOF
Usage: $0 -p PART -c CHAPTER -t TITLE [-d DESCRIPTION]

Generate a new chapter structure.

OPTIONS:
    -p, --part NUM        Part number (1, 2, 3, ...)
    -c, --chapter NUM     Chapter number (1, 2, 3, ...)
    -t, --title TITLE     Chapter title
    -d, --desc TEXT       Chapter description (optional)
    -s, --sections LIST   Comma-separated section names
    -h, --help           Show this help

EXAMPLES:
    $0 -p 1 -c 3 -t "Data Structures"
    $0 -p 2 -c 1 -t "Algorithms" -s "Introduction,Analysis,Implementation"

NOTES:
    - Creates chapter directory and file
    - Generates boilerplate content
    - Can create initial sections

EOF
}

PART=""
CHAPTER=""
TITLE=""
DESCRIPTION=""
SECTIONS=""

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
        -d|--desc)
            DESCRIPTION="$2"
            shift 2
            ;;
        -s|--sections)
            SECTIONS="$2"
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

PADDED_PART=$(pad_number "$PART")
PADDED_CHAPTER=$(pad_number "$CHAPTER")

PART_DIR="parts/part$PADDED_PART"
CHAPTER_DIR="$PART_DIR/chapter$PADDED_CHAPTER"
CHAPTER_FILE="$CHAPTER_DIR/chapter$PADDED_CHAPTER.tex"

[[ ! -d "$PART_DIR" ]] && error "Part directory not found: $PART_DIR. Create part first."
[[ -d "$CHAPTER_DIR" ]] && error "Chapter already exists: $CHAPTER_DIR"

log "Creating chapter $PART.$CHAPTER: $TITLE"
ensure_dir "$CHAPTER_DIR"
ensure_dir "$CHAPTER_DIR/figures"

# Generate chapter file
{
    cat <<EOF
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

    # Generate sections
    if [[ -n "$SECTIONS" ]]; then
        IFS=',' read -ra SECTION_ARRAY <<< "$SECTIONS"
        for section in "${SECTION_ARRAY[@]}"; do
            section=$(echo "$section" | xargs) # trim whitespace
            cat <<SECTION

\\section{$section}

Content for $section.

SECTION
        done
    else
        cat <<DEFSECTIONS

\\section{Introduction}

Opening section.

\\section{Main Content}

Core material.

\\subsection{Details}

Detailed explanation.

\\section{Examples}

Concrete examples.

\\begin{example}
Example content here.
\\end{example}

DEFSECTIONS
    fi

    cat <<EOF

\\section{Summary}

Chapter summary and key takeaways.

\\begin{keyidea}
The main idea of this chapter is...
\\end{keyidea}

EOF
} > "$CHAPTER_FILE"

log "Created: $CHAPTER_FILE"
info ""
info "Next steps:"
info "  1. Add to $PART_DIR/part$PADDED_PART.tex after the \\end{partintro}:"
info "     \\input{$CHAPTER_FILE}"
info "  2. Edit chapter content: $CHAPTER_FILE"
info "  3. Add figures to: $CHAPTER_DIR/figures/"