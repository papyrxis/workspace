#!/usr/bin/env bash

set -euo pipefail

build_usage() {
    cat <<'EOF'
Usage: bash workspace/src/build.sh [OPTIONS] [FILE.tex]

Build the LaTeX document.

OPTIONS:
  -s, --source FILE   Source .tex file (default: from workspace.yml → main.tex)
  -o, --output DIR    Output directory (default: build)
  -e, --engine NAME   Engine: pdflatex|xelatex|lualatex (default: pdflatex)
  -b, --bibtex NAME   Bibliography: biber|bibtex (default: biber)
  -c, --clean         Clean build dir before building
  -w, --watch         Watch for changes and auto-rebuild
  -q, --quiet         Suppress non-error output
  -h, --help          Show this help

EXAMPLES:
  make                                  # build (uses workspace.yml settings)
  make build                            # same
  make watch                            # watch mode
  bash workspace/src/build.sh -s my.tex # build specific file
EOF
}

part_usage() {
    cat <<'EOF'
Usage: make part ARGS='-n NUM -t "Title"'

Generate a new part for a book.

  -n, --number NUM    Part number
  -t, --title TITLE   Part title
  -d, --desc TEXT     Description (optional)

EXAMPLE:
  make part ARGS='-n 2 -t "Memory and Machines"'
EOF
}

chapter_usage() {
    cat <<'EOF'
Usage: make chapter ARGS='-p PART -c NUM -t "Title"'

Generate a new chapter inside a part.

  -p, --part NUM      Part number
  -c, --chapter NUM   Chapter number
  -t, --title TITLE   Chapter title
  -d, --desc TEXT     Description (optional)
  -s, --sections LIST Comma-separated section names (optional)

EXAMPLES:
  make chapter ARGS='-p 1 -c 2 -t "Bits and Bytes"'
  make chapter ARGS='-p 1 -c 3 -t "Memory" -s "Stack,Heap,Virtual"'
EOF
}

frontmatter_usage() {
    cat <<'EOF'
Usage: bash workspace/src/generator/frontmatter.sh -t TYPE [-f] [CONFIG]

Generate a frontmatter file from template.

  -t TYPE    Type: preface|acknowledgments|introduction
  -f         Force overwrite if file already exists

EXAMPLE:
  bash workspace/src/generator/frontmatter.sh -t preface
EOF
}

export -f build_usage part_usage chapter_usage frontmatter_usage
