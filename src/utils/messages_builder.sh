#!/usr/bin/env bash

set -euo pipefail

init_usage() {
    cat <<'EOF'
Usage: $0 [OPTIONS]

Initialize a new LaTeX project with Papyrxis workspace.

OPTIONS:
    -t, --type TYPE         Project type: book|article (required)
    -c, --category CAT      Category: technical|academic (default: technical)
    -n, --name NAME         Project name (default: current directory name)
    --title TITLE          Document title
    --author AUTHOR        Author name (default: from git config)
    --email EMAIL          Author email (default: from git config)
    --url URL              Project URL (auto-detected from git remote)
    -d, --dir DIR          Target directory (default: current directory)
    --interactive          Interactive mode (prompt for all values)
    -h, --help             Show this help

EXAMPLES:
    $0 -t book --title "My Book"
    $0 -t book --interactive
    $0 -t article --author "John Doe" --email "john@example.com"

EOF
}

build_usage() {
    cat <<'EOF'
Usage: $0 [OPTIONS] [SOURCE.tex]

Build LaTeX document with proper dependency handling.

OPTIONS:
    -o, --output DIR     Output directory (default: from config or 'build')
    -e, --engine ENGINE  LaTeX engine: pdflatex|xelatex|lualatex
    -b, --bibtex TOOL    Bibliography tool: biber|bibtex
    -c, --clean          Clean build directory before building
    -w, --watch          Watch mode: rebuild on file changes
    -q, --quiet          Suppress non-error output
    -h, --help           Show this help

EXAMPLES:
    $0                   # Build main.tex with config settings
    $0 main.tex         # Build specific file
    $0 -w               # Watch mode
    $0 -c -e xelatex    # Clean build with XeLaTeX

EOF
}

sync_usage() {
    cat <<'EOF'
Usage: $0

Synchronize workspace components based on workspace.yml.

No options required. Configuration comes from workspace.yml.

EXAMPLES:
    $0                   # Sync components

EOF
}

update_usage() {
    cat <<'EOF'
Usage: $0 [OPTIONS]

Update Papyrxis workspace to latest version.

OPTIONS:
    -f, --force          Force update even if uncommitted changes
    -b, --backup         Create backup before update
    -c, --check          Check for updates without applying
    -v, --verbose        Show detailed output
    -h, --help           Show this help

EXAMPLES:
    $0                   # Check and update
    $0 -b                # Backup and update
    $0 -c                # Just check

EOF
}

part_usage() {
    cat <<'EOF'
Usage: $0 -n NUMBER -t TITLE [-d DESCRIPTION]

Generate a new part structure for a book.

OPTIONS:
    -n, --number NUM      Part number (1, 2, 3, ...)
    -t, --title TITLE     Part title
    -d, --desc TEXT       Part description (optional)
    -h, --help           Show this help

EXAMPLE:
    $0 -n 2 -t "Advanced Topics" -d "Deep dive"

EOF
}

chapter_usage() {
    cat <<'EOF'
Usage: $0 -p PART -c CHAPTER -t TITLE [-d DESCRIPTION] [-s SECTIONS]

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
    $0 -p 2 -c 1 -t "Algorithms" -s "Introduction,Analysis"

EOF
}

frontmatter_usage() {
    cat <<'EOF'
Usage: $0 -t TYPE [-f] [CONFIG_FILE]

Generate frontmatter file from template.

OPTIONS:
    -t, --type TYPE       Type: preface|acknowledgments|introduction
    -f, --force           Force overwrite existing file
    -h, --help           Show this help

ARGUMENTS:
    CONFIG_FILE          Configuration file (default: workspace.yml)

EXAMPLES:
    $0 -t preface
    $0 -t introduction -f

EOF
}

export -f init_usage build_usage sync_usage update_usage
export -f part_usage chapter_usage frontmatter_usage