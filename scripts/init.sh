#!/usr/bin/env bash
# Initialize a new Papyrxis project from templates

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
    --author AUTHOR        Author name (default: from git config)
    --email EMAIL          Author email (default: from git config)
    --url URL              Project URL (auto-detected from git remote)
    -d, --dir DIR          Target directory (default: current directory)
    --interactive          Interactive mode (prompt for all values)
    -h, --help             Show this help

EXAMPLES:
    # Quick start with auto-detection
    $0 -t book --title "My Book"
    
    # Interactive mode
    $0 -t book --interactive
    
    # Full specification
    $0 -t article --author "John Doe" --email "john@example.com" --url "https://github.com/user/repo"

NOTES:
    - Creates workspace.yml configuration file
    - Sets up directory structure from templates
    - Detects git config for author info
    - Detects git remote for URL
    - Templates are populated with your values

EOF
}

# Defaults
TYPE=""
CATEGORY="technical"
NAME=""
TITLE=""
AUTHOR=""
EMAIL=""
URL=""
TARGET_DIR="."
INTERACTIVE=false

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
        --url)
            URL="$2"
            shift 2
            ;;
        -d|--dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        --interactive)
            INTERACTIVE=true
            shift
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

# Validate type
[[ -z "$TYPE" ]] && error "Project type required (-t book|article)"
[[ "$TYPE" != "book" && "$TYPE" != "article" ]] && error "Invalid type: $TYPE (must be book or article)"
[[ "$CATEGORY" != "technical" && "$CATEGORY" != "academic" ]] && error "Invalid category: $CATEGORY"

# Auto-detect from git if available
detect_git_info() {
    if command_exists git && git rev-parse --git-dir > /dev/null 2>&1; then
        [[ -z "$AUTHOR" ]] && AUTHOR=$(git config user.name 2>/dev/null || echo "")
        [[ -z "$EMAIL" ]] && EMAIL=$(git config user.email 2>/dev/null || echo "")
        
        if [[ -z "$URL" ]]; then
            local remote=$(git config --get remote.origin.url 2>/dev/null || echo "")
            if [[ -n "$remote" ]]; then
                # Convert SSH to HTTPS
                if [[ "$remote" =~ ^git@ ]]; then
                    URL=$(echo "$remote" | sed 's|git@\(.*\):\(.*\)\.git|https://\1/\2|')
                else
                    URL="$remote"
                fi
            fi
        fi
    fi
}

detect_git_info

# Set defaults
[[ -z "$NAME" ]] && NAME=$(basename "$(realpath "$TARGET_DIR")")
[[ -z "$TITLE" ]] && TITLE="$NAME"
[[ -z "$AUTHOR" ]] && AUTHOR="Author Name"
[[ -z "$EMAIL" ]] && EMAIL=""
[[ -z "$URL" ]] && URL="https://github.com/user/$NAME"

# Interactive mode
if $INTERACTIVE; then
    read -p "Project name [$NAME]: " input && [[ -n "$input" ]] && NAME="$input"
    read -p "Document title [$TITLE]: " input && [[ -n "$input" ]] && TITLE="$input"
    read -p "Author name [$AUTHOR]: " input && [[ -n "$input" ]] && AUTHOR="$input"
    read -p "Author email [$EMAIL]: " input && [[ -n "$input" ]] && EMAIL="$input"
    read -p "Project URL [$URL]: " input && [[ -n "$input" ]] && URL="$input"
    read -p "Category [$CATEGORY]: " input && [[ -n "$input" ]] && CATEGORY="$input"
fi

# Create target directory
ensure_dir "$TARGET_DIR"
cd "$TARGET_DIR"

log "Initializing $TYPE project: $NAME"
log "Category: $CATEGORY"
log "Author: $AUTHOR"
[[ -n "$EMAIL" ]] && log "Email: $EMAIL"
log "URL: $URL"

# Generate workspace.yml
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
  url: "$URL"
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

overrides:
  components_dir: "configs"
  allow:
    - colors.tex
    - commands/base.tex
    - pagestyles.tex
    - frontmatter/title.tex
    - frontmatter/copyright.tex
    - cover.tex
EOF

    # Create book structure
    log "Creating book structure from templates..."
    ensure_dir parts/part01
    ensure_dir frontmatter
    ensure_dir backmatter
    ensure_dir figures
    ensure_dir references
    ensure_dir configs
    
    # Copy and populate template main.tex for book
    if [[ -f "$WORKSPACE_ROOT/template/books/main.tex" ]]; then
        sed -e "s|\\\\newcommand{\\\\PDFTitle}{.*}|\\\\newcommand{\\\\PDFTitle}{$TITLE}|" \
            -e "s|\\\\newcommand{\\\\PDFTitleFront}{.*}|\\\\newcommand{\\\\PDFTitleFront}{$TITLE}|" \
            -e "s|\\\\newcommand{\\\\PDFCoverTitle}{.*}|\\\\newcommand{\\\\PDFCoverTitle}{$TITLE}|" \
            -e "s|\\\\newcommand{\\\\PDFAuthor}{.*}|\\\\newcommand{\\\\PDFAuthor}{$AUTHOR}|" \
            -e "s|\\\\newcommand{\\\\PDFURL}{.*}|\\\\newcommand{\\\\PDFURL}{$URL}|" \
            "$WORKSPACE_ROOT/template/books/main.tex" > main.tex
    fi
    
    # Copy frontmatter templates
    for fm in preface; do
        if [[ -f "$WORKSPACE_ROOT/template/books/frontmatter/$fm.tex" ]]; then
            sed -e "s/Author Name/$AUTHOR/g" \
                -e "s|Book Title|$TITLE|g" \
                "$WORKSPACE_ROOT/template/books/frontmatter/$fm.tex" > "frontmatter/$fm.tex"
        fi
    done
    
    # Copy part template
    if [[ -f "$WORKSPACE_ROOT/template/books/parts/part01.tex" ]]; then
        cp "$WORKSPACE_ROOT/template/books/parts/part01.tex" "parts/part01/part01.tex"
    fi
    
    # Copy backmatter
    if [[ -d "$WORKSPACE_ROOT/template/books/backmatter" ]]; then
        cp -r "$WORKSPACE_ROOT/template/books/backmatter/"* backmatter/ 2>/dev/null || true
    fi

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

overrides:
  components_dir: "configs"
  allow:
    - colors.tex
    - commands/base.tex
EOF

    # Create article structure
    log "Creating article structure from templates..."
    ensure_dir sections
    ensure_dir figures
    ensure_dir references
    ensure_dir configs
    
    # Determine which article template
    TEMPLATE_DIR="$WORKSPACE_ROOT/template/article/single-column"
    if [[ "$CATEGORY" == "academic" ]]; then
        TEMPLATE_DIR="$WORKSPACE_ROOT/template/article/ieee"
    fi
    
    # Copy and populate main.tex
    if [[ -f "$TEMPLATE_DIR/main.tex" ]]; then
        sed -e "s|Article Title|$TITLE|g" \
            -e "s|Author Name|$AUTHOR|g" \
            -e "s|email@example.com|$EMAIL|g" \
            "$TEMPLATE_DIR/main.tex" > main.tex
    fi
fi

# Create Makefile (same for both)
if [[ -f "$WORKSPACE_ROOT/template/Makefile" ]]; then
    cp "$WORKSPACE_ROOT/template/Makefile" Makefile
fi

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
.pxis/

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

## Quick Start

\`\`\`bash
make
\`\`\`

This will sync workspace components and build your document.

## Watch Mode

Auto-rebuild on file changes:

\`\`\`bash
make watch
\`\`\`

## Customization

Edit \`workspace.yml\` to configure:
- Components to include
- Color schemes
- Features (TOC, index, bibliography)
- Front matter sections
- Copyright settings

To override workspace components, place your custom versions in \`configs/\` directory.

## Building

The build process:
1. Reads your \`workspace.yml\` configuration
2. Syncs required components to \`.pxis/\` directory
3. Generates frontmatter (cover, copyright, etc.)
4. Builds the final PDF

## Structure

$(if [[ "$TYPE" == "book" ]]; then cat <<BOOKSTRUCT
- \`frontmatter/\` - Front matter pages (preface, introduction, etc.)
- \`parts/\` - Book parts and chapters
- \`backmatter/\` - Appendices and back matter
- \`figures/\` - Image files
- \`references/\` - Bibliography files
- \`configs/\` - Custom component overrides
- \`.pxis/\` - Synced workspace files (auto-generated)
BOOKSTRUCT
else cat <<ARTICLESTRUCT
- \`sections/\` - Article sections (optional)
- \`figures/\` - Image files
- \`references/\` - Bibliography files
- \`configs/\` - Custom component overrides
- \`.pxis/\` - Synced workspace files (auto-generated)
ARTICLESTRUCT
fi)

## Version Management

Version is automatically generated from git tags. Format: v{major}.{minor}.{patch}

To create a version:
\`\`\`bash
git tag v1.0.0
\`\`\`

## Documentation

See workspace/docs/ for detailed documentation:
- getting-started.md - Complete setup guide
- configuration.md - All configuration options
- customization.md - How to customize everything
- templates.md - Template documentation

## License

See copyright information in the document.
EOFREADME

log "Project initialized successfully!"
info ""
info "Next steps:"
info "  1. Review and edit workspace.yml"
info "  2. Run 'make' to build"
info "  3. Run 'make watch' for development"
info ""
info "Files created:"
info "  - workspace.yml (configuration)"
info "  - main.tex (document entry point)"
info "  - Makefile (build automation)"
info "  - README.md (project documentation)"
info ""
info "Directory structure:"
if [[ "$TYPE" == "book" ]]; then
    info "  - parts/ (book content)"
    info "  - frontmatter/ (preface, intro, etc.)"
    info "  - backmatter/ (appendices)"
fi
info "  - figures/ (images)"
info "  - references/ (bibliography)"
info "  - configs/ (custom overrides)"