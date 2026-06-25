#!/usr/bin/env bash

set -euo pipefail

init_workspace() {
    ensure_dir "$TARGET_DIR"
    cd "$TARGET_DIR" || error "Cannot enter: $TARGET_DIR"

    if check_workspace_file; then
        info "workspace.yml already exists — loading"
        load_config "$WORKSPACE_FILE"
    else
        generate_workspace_file
        setup_structure
    fi

    setup_main_tex
    setup_makefile
    setup_gitignore
    setup_github_workflows
}

generate_workspace_file() {
    log "Creating workspace.yml..."

    local src_file="${SOURCE:-main.tex}"

    cat > workspace.yml <<EOF
project:
  type: $TYPE
  title: "$TITLE"
  author: "$AUTHOR"
  email: "${EMAIL:-}"
  url: "$URL"

build:
  engine: pdflatex
  bibtex: biber
  output_dir: build
  source: "$src_file"

version:
  source: git
  fallback: "dev"

components:
EOF

    if [[ "$TYPE" == "book" ]]; then
        cat >> workspace.yml <<EOF
  - fonts
  - math
  - graphics
  - tables
  - hyperref
  - colors
  - layout
  - titles
  - pagestyles
  - env
  - index
  - bibliography
  - code
  - boxes
  - commands/base

frontmatter:
  - cover
  - title
  - copyright
  - preface
  - introduction

EOF
    else
        cat >> workspace.yml <<EOF
  - fonts
  - math
  - graphics
  - tables
  - hyperref
  - colors
  - layout
  - bibliography
  - code
  - commands/base

EOF
    fi

    cat >> workspace.yml <<EOF
colors:
  scheme: technical

copyright:
  type: cc-by-sa
  year: "auto"
  holder: "$AUTHOR"

overrides:
  dir: "configs"
  # mode: replace   (default) — your file replaces the default component
  # mode: extend    — default component first, then your additions appended

cover:
  type: generated
  generated:
    style: modern
EOF

    success "workspace.yml created"
}

setup_structure() {
    log "Creating directory structure..."

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

    success "Directories ready"
}

setup_main_tex() {
    local src_file="${SOURCE:-main.tex}"

    if [[ -f "$src_file" ]]; then
        info "$src_file already exists — skipping"
        return 0
    fi

    log "Creating $src_file..."

    if [[ "$TYPE" == "book" ]]; then
        local template="$WORKSPACE_ROOT/template/books/main.tex"
        if [[ -f "$template" ]]; then
            sed -e "s|{{TITLE}}|$TITLE|g" \
                -e "s|{{AUTHOR}}|$AUTHOR|g" \
                -e "s|{{EMAIL}}|${EMAIL:-}|g" \
                -e "s|{{URL}}|$URL|g" \
                "$template" > "$src_file"
        else
            create_book_tex "$src_file"
        fi
    else
        local template="$WORKSPACE_ROOT/template/article/main.tex"
        if [[ -f "$template" ]]; then
            sed -e "s|{{TITLE}}|$TITLE|g" \
                -e "s|{{AUTHOR}}|$AUTHOR|g" \
                -e "s|{{EMAIL}}|${EMAIL:-}|g" \
                -e "s|{{URL}}|$URL|g" \
                "$template" > "$src_file"
        else
            create_article_tex "$src_file"
        fi
    fi

    success "Created: $src_file"
}

create_book_tex() {
    local file="$1"
    cat > "$file" <<'EOF'
\documentclass[12pt,oneside,openany]{book}

\newcommand{\PDFTitle}{Title}
\newcommand{\PDFAuthor}{Author}
\newcommand{\PDFURL}{URL}

\input{.pxis/preset}

\begin{document}

\frontmatter
\input{frontmatter/cover}
\input{frontmatter/title}
\input{frontmatter/copyright}

\tableofcontents

\mainmatter
\input{parts/part01/part01}

\backmatter
\printbibliography
\printindex

\end{document}
EOF
}

create_article_tex() {
    local file="$1"
    cat > "$file" <<'EOF'
\documentclass[12pt,a4paper]{article}

\input{.pxis/preset}

\addbibresource{references/main.bib}

\begin{document}

\begin{titlepage}
  \centering
  \vspace*{2cm}
  {\Huge\bfseries Title\par}
  \vspace{0.5cm}
  {\large Subtitle (optional)\par}
  \vspace{2cm}
  {\large Author Name\par}
  {\small \texttt{email@example.com}\par}
  \vfill
  {\small \today\par}
\end{titlepage}

\begin{abstract}
Abstract here.
\end{abstract}

\paragraph{Keywords} keyword1, keyword2, keyword3

\tableofcontents

\section{Introduction}

\section{Problem Statement}

\section{Background}

\section{Approach}

\section{Analysis}

\section{Example}

\section{Discussion}

\section{Conclusion}

\printbibliography

\end{document}
EOF
}

setup_makefile() {
    if [[ -f "Makefile" ]]; then
        info "Makefile exists — skipping"
        return 0
    fi

    log "Creating Makefile..."
    local tmpl="$WORKSPACE_ROOT/Makefile"
    if [[ -f "$tmpl" ]]; then
        cp "$tmpl" Makefile
        success "Makefile created"
    else
        warn "Makefile template not found"
    fi
}

setup_gitignore() {
    if [[ -f ".gitignore" ]]; then
        info ".gitignore exists — skipping"
        return 0
    fi

    log "Creating .gitignore..."
    cat > .gitignore <<'EOF'
# LaTeX build artifacts
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
*.run.xml
*.bcf

# Editor
*.swp
*.swo
.DS_Store
EOF
    success ".gitignore created"
}

setup_github_workflows() {
    ensure_dir ".github/workflows"

    # Only copy if not already present
    local wf_src="$WORKSPACE_ROOT/template/workflows"
    if [[ ! -d "$wf_src" ]]; then
        return 0
    fi

    for wf in "$wf_src"/*.yml; do
        local name
        name=$(basename "$wf")
        if [[ ! -f ".github/workflows/$name" ]]; then
            log "  · workflow: $name"
            cp "$wf" ".github/workflows/$name"
        else
            info "  · workflow $name exists — skipping"
        fi
    done
}

export -f init_workspace generate_workspace_file setup_structure
export -f setup_main_tex create_book_tex create_article_tex
export -f setup_makefile setup_gitignore setup_github_workflows
