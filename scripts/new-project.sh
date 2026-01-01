#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Create a new LaTeX project from template.

OPTIONS:
    -t, --type TYPE         Project type: book|article (required)
    -c, --category CAT      Category: technical|academic|general (default: general)
    -n, --name NAME         Project name (required)
    -d, --dir DIR           Project directory (default: current directory)
    -p, --preset PRESET     Use specific preset
    --title TITLE          Document title
    --author AUTHOR        Document author
    -h, --help             Show this help

EXAMPLES:
    $0 -t book -c technical -n my-book --title "My Technical Book"
    $0 -t article -c academic -n my-paper --author "John Doe"
EOF
}

TYPE=""
CATEGORY="general"
NAME=""
DIR="."
PRESET=""
TITLE=""
AUTHOR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            TYPE="$2"
            shift 2
            ;;
        -c|--category)
            CATEGORY="$2"
            shift 2
            ;;
        -n|--name)
            NAME="$2"
            shift 2
            ;;
        -d|--dir)
            DIR="$2"
            shift 2
            ;;
        -p|--preset)
            PRESET="$2"
            shift 2
            ;;
        --title)
            TITLE="$2"
            shift 2
            ;;
        --author)
            AUTHOR="$2"
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

[[ -z "$TYPE" ]] && error "Project type required (-t)"
[[ -z "$NAME" ]] && error "Project name required (-n)"

[[ "$TYPE" != "book" && "$TYPE" != "article" ]] && error "Invalid type: $TYPE"

PROJECT_DIR="$DIR/$NAME"

if [[ -d "$PROJECT_DIR" ]]; then
    read -p "Directory $PROJECT_DIR exists. Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Aborted"
        exit 0
    fi
    rm -rf "$PROJECT_DIR"
fi

log "Creating project: $NAME"
log "Type: $TYPE"
log "Category: $CATEGORY"

mkdir -p "$PROJECT_DIR"

if [[ "$TYPE" == "book" ]]; then
    log "Setting up book structure..."
    
    mkdir -p "$PROJECT_DIR"/{frontmatter,parts,backmatter,figures,references}
    
    cat > "$PROJECT_DIR/main.tex" <<EOF
\\documentclass[12pt,oneside,openany]{book}

\\newcommand{\\PDFTitle}{${TITLE:-$NAME}}
\\newcommand{\\PDFTitleFront}{${TITLE:-$NAME}}
\\newcommand{\\PDFCoverTitle}{${TITLE:-$NAME}}
\\newcommand{\\PDFCoverDescription}{${CATEGORY^} Book}
\\newcommand{\\PDFSubject}{${CATEGORY^} Topics}
\\newcommand{\\PDFKeywords}{}
\\newcommand{\\PDFLOGO}{cover.pdf}
\\newcommand{\\PDFURL}{https://github.com/user/repo}

\\input{../../common/presets/book/${CATEGORY}}

\\begin{document}

\\frontmatter
\\frontmatterpagenumber
\\input{../../common/frontmatter/title}
\\input{../../common/frontmatter/copyright}
\\tableofcontents

\\mainmatter
\\mainmatterpagenumber

\\part{Part One}
\\chapter{Chapter One}

Content here.

\\backmatter
\\end{document}
EOF

elif [[ "$TYPE" == "article" ]]; then
    log "Setting up article structure..."
    
    mkdir -p "$PROJECT_DIR"/{sections,figures,references}
    
    cat > "$PROJECT_DIR/main.tex" <<EOF
\\documentclass[12pt,a4paper]{article}

\\title{${TITLE:-$NAME}}
\\author{${AUTHOR:-Author Name}}
\\date{\\today}

\\input{../../common/presets/article/${CATEGORY}}

\\begin{document}
\\maketitle

\\begin{abstract}
Your abstract here.
\\end{abstract}

\\section{Introduction}

Content here.

\\bibliographystyle{plain}
\\bibliography{references/main}

\\end{document}
EOF
fi

cat > "$PROJECT_DIR/Makefile" <<'EOF'
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_DATE ?= $(shell date -u '+%Y-%m-%d_%H:%M:%S')

.PHONY: all build clean watch

all: build

build:
	@export VERSION=$(VERSION) BUILD_DATE=$(BUILD_DATE) && \
	../../scripts/build.sh -o build main.tex

clean:
	rm -rf build/

watch:
	../../scripts/build.sh -w main.tex
EOF

cat > "$PROJECT_DIR/.gitignore" <<EOF
build/
*.aux
*.log
*.out
*.toc
*.bbl
*.blg
*.synctex.gz
*.fdb_latexmk
*.fls
EOF

cat > "$PROJECT_DIR/README.md" <<EOF
# $NAME

${TITLE:-$NAME} - A ${CATEGORY} ${TYPE}.

## Building

\`\`\`bash
make
\`\`\`

## Watch mode

\`\`\`bash
make watch
\`\`\`

## Version

Current version: $VERSION
EOF

log "Project created successfully: $PROJECT_DIR"
log "Next steps:"
log "  cd $PROJECT_DIR"
log "  make"