#!/usr/bin/env bash
# Initialize a new Papyrxis project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/common.sh"

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Initialize a new LaTeX project with Papyrxis workspace.

OPTIONS:
    -t, --type TYPE         Project type: book|article (required)
    -c, --category CAT      Category: technical|academic (default: technical)
    -n, --name NAME         Project name (default: current directory name)
    --title TITLE          Document title
    --author AUTHOR        Author name
    --email EMAIL          Author email
    -d, --dir DIR          Target directory (default: current directory)
    -h, --help             Show this help

EXAMPLES:
    # Initialize in current directory
    $0 -t book -c technical --title "My Book"
    
    # Initialize in new directory
    $0 -t article --author "John Doe" -d ./my-paper

NOTES:
    - Creates workspace.yml configuration file
    - Sets up directory structure
    - Generates initial main.tex
    - Can be used with workspace as submodule

EOF
}

# Default values
TYPE=""
CATEGORY="technical"
NAME=""
TITLE=""
AUTHOR=""
EMAIL=""
TARGET_DIR="."

# Parse arguments
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
        --title)
            TITLE="$2"
            shift 2
            ;;
        --author)
            AUTHOR="$2"
            shift 2
            ;;
        --email)
            EMAIL="$2"
            shift 2
            ;;
        -d|--dir)
            TARGET_DIR="$2"
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

# Validate
[[ -z "$TYPE" ]] && error "Project type required (-t book|article)"
[[ "$TYPE" != "book" && "$TYPE" != "article" ]] && error "Invalid type: $TYPE (must be book or article)"
[[ "$CATEGORY" != "technical" && "$CATEGORY" != "academic" ]] && error "Invalid category: $CATEGORY"

# Set defaults
[[ -z "$NAME" ]] && NAME=$(basename "$(realpath "$TARGET_DIR")")
[[ -z "$TITLE" ]] && TITLE="$NAME"
[[ -z "$AUTHOR" ]] && AUTHOR="Author Name"

# Create target directory
ensure_dir "$TARGET_DIR"
cd "$TARGET_DIR"

log "Initializing $TYPE project: $NAME"
log "Category: $CATEGORY"

# Create workspace.yml
cat > workspace.yml <<EOF
# Papyrxis Workspace Configuration
# Generated: $(date)

project:
  type: $TYPE
  category: $CATEGORY
  title: "$TITLE"
  subtitle: ""
  author: "$AUTHOR"
  email: "$EMAIL"
  date: "auto"
  url: "https://github.com/user/$NAME"
  subject: "$CATEGORY project"
  keywords: "latex, $TYPE, $CATEGORY"

build:
  engine: pdflatex
  bibtex: biber
  output_dir: build
  watch_mode: true

version:
  source: git
  format: "v{major}.{minor}.{patch}"
  fallback: "dev"

components:
  - encoding
  - fonts
  - math
  - graphics
  - tables
  - hyperref
  - colors
  - layout
  - titles
EOF

if [[ "$TYPE" == "book" ]]; then
    cat >> workspace.yml <<EOF
  - pagestyles
  - env
  - index
  - bibliography
  - code
  - boxes
  - commands/base

features:
  toc: true
  index: true
  bibliography: true
  glossary: false
  appendix: true

frontmatter:
  - cover
  - title
  - copyright
  - preface
  - acknowledgments
  - introduction

colors:
  scheme: $CATEGORY

copyright:
  type: cc-by-sa
  year: "auto"
  holder: "$AUTHOR"

cover:
  type: generated
  generated:
    style: modern
    title_size: large
    include_subtitle: true
    include_author: true
EOF

    # Create book structure
    ensure_dir parts/part01
    ensure_dir frontmatter
    ensure_dir backmatter
    ensure_dir figures
    ensure_dir references
    ensure_dir custom
    
    log "Creating book structure..."
    
    # Create main.tex for book
    cat > main.tex <<'EOFMAIN'
\documentclass[12pt,oneside,openany]{book}

% Metadata
\newcommand{\PDFTitle}{\CONFIG{project.title}}
\newcommand{\PDFTitleFront}{\CONFIG{project.title}}
\newcommand{\PDFCoverTitle}{\CONFIG{project.title}}
\newcommand{\PDFSubject}{\CONFIG{project.subject}}
\newcommand{\PDFKeywords}{\CONFIG{project.keywords}}
\newcommand{\PDFAuthor}{\CONFIG{project.author}}
\newcommand{\PDFURL}{\CONFIG{project.url}}

% Import workspace components (will be synced)
\input{workspace/preset}

\begin{document}

\frontmatter
\input{frontmatter/cover}
\input{frontmatter/title}
\input{frontmatter/copyright}

\tableofcontents

\input{frontmatter/preface}
\input{frontmatter/acknowledgments}
\input{frontmatter/introduction}

\mainmatter

\input{parts/part01/part01}

\backmatter

\appendix
\input{backmatter/appendix}

\printbibliography[title={Bibliography}]
\addcontentsline{toc}{chapter}{Bibliography}

\printindex
\addcontentsline{toc}{chapter}{Index}

\end{document}
EOFMAIN

    # Create initial part
    cat > parts/part01/part01.tex <<EOFPART
\part{Introduction}
\label{part:part01}

\begin{partintro}
\lettrine{T}{his} is the first part of the book.

Overview of what this part covers.
\end{partintro}

\chapter{First Chapter}
\label{ch:chapter01}

\begin{chapterintro}
Introduction to the first chapter.
\end{chapterintro}

\section{Introduction}

Content goes here.

\section{Summary}

Chapter summary.
EOFPART

else
    # Article configuration
    cat >> workspace.yml <<EOF
  - bibliography
  - code
  - commands/base

colors:
  scheme: $CATEGORY

copyright:
  type: cc-by-sa
  year: "auto"
  holder: "$AUTHOR"
EOF

    # Create article structure
    ensure_dir sections
    ensure_dir figures
    ensure_dir references
    ensure_dir custom
    
    log "Creating article structure..."
    
    # Create main.tex for article
    cat > main.tex <<'EOFMAIN'
\documentclass[12pt,a4paper]{article}

\title{\CONFIG{project.title}}
\author{\CONFIG{project.author}}
\date{\today}

% Import workspace components (will be synced)
\input{workspace/preset}

\addbibresource{references/main.bib}

\begin{document}

\maketitle

\begin{abstract}
Your abstract here.
\end{abstract}

\section{Introduction}

Introduction content.

\section{Methodology}

Methodology description.

\section{Results}

Results and discussion.

\section{Conclusion}

Conclusion and future work.

\printbibliography

\end{document}
EOFMAIN
fi

# Create Makefile
cat > Makefile <<'EOFMAKE'
.PHONY: all build clean watch sync help

WORKSPACE := workspace

all: sync build

sync:
	@bash $(WORKSPACE)/scripts/sync.sh

build: sync
	@bash $(WORKSPACE)/scripts/build.sh main.tex

clean:
	@rm -rf build/
	@find . -name "*.aux" -o -name "*.log" -o -name "*.out" \
	   -o -name "*.toc" -o -name "*.bbl" -o -name "*.blg" | xargs rm -f

watch: sync
	@bash $(WORKSPACE)/scripts/build.sh -w main.tex

help:
	@echo "Papyrxis Workspace - Available targets:"
	@echo "  make sync   - Sync workspace components"
	@echo "  make build  - Build document"
	@echo "  make watch  - Watch mode (auto-rebuild)"
	@echo "  make clean  - Clean build artifacts"
	@echo "  make help   - Show this help"
EOFMAKE

# Create .gitignore
cat > .gitignore <<'EOFGITIGNORE'
# Build artifacts
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
*.idx
*.ilg
*.ind

# Synced workspace files (regenerated by make sync)
workspace/preset.tex
workspace/components/

# OS files
.DS_Store
Thumbs.db

# Editor files
*.swp
*.swo
*~
.vscode/
.idea/
EOFGITIGNORE

# Create README
cat > README.md <<EOFREADME
# $TITLE

A $CATEGORY $TYPE project using Papyrxis workspace.

## Building

\`\`\`bash
make
\`\`\`

This will:
1. Sync workspace components based on workspace.yml
2. Build the document with appropriate engine

## Watch Mode

Auto-rebuild on file changes:

\`\`\`bash
make watch
\`\`\`

## Customization

Edit \`workspace.yml\` to configure components, colors, features, etc.

To override workspace components, create files in \`custom/\` directory.

## Version

Version is automatically generated from git tags.

## Structure

$(if [[ "$TYPE" == "book" ]]; then cat <<BOOKSTRUCT
- \`frontmatter/\` - Front matter pages
- \`parts/\` - Book parts and chapters
- \`backmatter/\` - Appendices and back matter
- \`figures/\` - Image files
- \`references/\` - Bibliography files
BOOKSTRUCT
else cat <<ARTICLESTRUCT
- \`sections/\` - Article sections (optional)
- \`figures/\` - Image files
- \`references/\` - Bibliography files
ARTICLESTRUCT
fi)
- \`custom/\` - Custom component overrides
- \`workspace/\` - Synced workspace files (auto-generated)

## License

See copyright information in the document.
EOFREADME

log "Project initialized successfully!"
info "Next steps:"
info "  1. Add workspace as submodule (if not already):"
info "     git submodule add https://github.com/papyrxis/workspace.git workspace"
info "  2. Edit workspace.yml to configure your project"
info "  3. Run 'make' to build"
info ""
info "Or if workspace already exists:"
info "  make"