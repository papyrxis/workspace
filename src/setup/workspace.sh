#!/usr/bin/env bash

set -euo pipefail

init_workspace() {
    ensure_dir "$TARGET_DIR"
    cd "$TARGET_DIR" || error "Failed to enter $TARGET_DIR"
    
    if check_workspace_file; then
        info "workspace.yml already exists, loading existing config"
        load_config "$WORKSPACE_FILE"
       
        TYPE=$(get_config "project.type" "$TYPE")
        CATEGORY=$(get_config "project.category" "$CATEGORY")
        TITLE=$(get_config "project.title" "$TITLE")
        AUTHOR=$(get_config "project.author" "$AUTHOR")
        EMAIL=$(get_config "project.email" "$EMAIL")
        URL=$(get_config "project.url" "$URL")
        SUBTITLE=$(get_config "project.subtitle" "$SUBTITLE")
        SUBJECT=$(get_config "project.subject" "$SUBJECT")
        KEYWORDS=$(get_config "project.keywords" "$KEYWORDS")
    else 
        generate_workspace_file
        setup_project_structure
    fi
    setup_main_tex
    setup_makefile
}

generate_workspace_file() {
    log "Generating workspace.yml..."
    
    cat > workspace.yml <<EOF
project:
  type: $TYPE
  category: $CATEGORY
  title: "$TITLE"
  subtitle: "${SUBTITLE:-}"
  author: "$AUTHOR"
  email: "${EMAIL:-}"
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
EOF
    else
        cat >> workspace.yml <<EOF
  - bibliography
  - code
  - commands/base
EOF
    fi
    
    cat >> workspace.yml <<EOF

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

    if [[ "$TYPE" == "book" ]]; then
        cat >> workspace.yml <<EOF
    - pagestyles.tex
    - frontmatter/title.tex
    - frontmatter/copyright.tex
    - cover.tex

cover:
  type: generated
  generated:
    style: modern
    title_size: large
    include_subtitle: true
    include_author: true
EOF
    fi
    
    success "Created workspace.yml"
}

setup_project_structure() {
    log "Setting up project structure..."
    
    if [[ "$TYPE" == "book" ]]; then
        ensure_dir parts/part01
        ensure_dir frontmatter
        ensure_dir backmatter
    else
        ensure_dir sections
    fi
    
    ensure_dir figures
    ensure_dir references
    ensure_dir configs
    
    success "Created directory structure"
}

setup_main_tex() {
    if [[ -f "main.tex" ]]; then
        info "main.tex already exists, skipping"
        return 0
    fi
    
    log "Creating main.tex..."
    
    local template_file
    if [[ "$TYPE" == "book" ]]; then
        template_file="$WORKSPACE_ROOT/template/books/main.tex"
    else
        template_file="$WORKSPACE_ROOT/template/article/single-column/main.tex"
    fi
    
    if [[ -f "$template_file" ]]; then
        sed -e "s|{{TITLE}}|$TITLE|g" \
            -e "s|{{AUTHOR}}|$AUTHOR|g" \
            -e "s|{{EMAIL}}|$EMAIL|g" \
            -e "s|{{URL}}|$URL|g" \
            -e "s|{{SUBJECT}}|$SUBJECT|g" \
            -e "s|{{KEYWORDS}}|$KEYWORDS|g" \
            "$template_file" > main.tex
        success "Created main.tex from template"
    else
        warn "Template not found, creating basic main.tex"
        create_basic_main_tex
    fi
}

create_basic_main_tex() {
    if [[ "$TYPE" == "book" ]]; then
        cat > main.tex <<'EOF'
\documentclass[12pt,oneside,openany]{book}

\newcommand{\PDFTitle}{Title}
\newcommand{\PDFTitleFront}{Title}
\newcommand{\PDFAuthor}{Author}
\newcommand{\PDFURL}{URL}

\input{.pxis/preset}

\begin{document}

\frontmatter
\frontmatterpagenumber

\input{frontmatter/title}
\input{frontmatter/copyright}

\tableofcontents

\mainmatter
\mainmatterpagenumber

\input{parts/part01/part01}

\backmatter

\printbibliography
\printindex

\end{document}
EOF
    else
        cat > main.tex <<'EOF'
\documentclass[12pt,a4paper]{article}

\input{.pxis/preset}

\title{Title}
\author{Author}
\date{\today}

\begin{document}

\maketitle

\begin{abstract}
Abstract here.
\end{abstract}

\section{Introduction}

Content here.

\printbibliography

\end{document}
EOF
    fi
}

setup_makefile() {
    if [[ -f "Makefile" ]]; then
        info "Makefile already exists, skipping"
        return 0
    fi
    
    log "Creating Makefile..."
    
    local template_makefile="$WORKSPACE_ROOT/template/books/Makefile"
    if [[ -f "$template_makefile" ]]; then
        cp "$template_makefile" Makefile
        success "Created Makefile"
    else
        warn "Makefile template not found"
    fi
}

export -f init_workspace generate_workspace_file setup_project_structure
export -f setup_main_tex create_basic_main_tex setup_makefile