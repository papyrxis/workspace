#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"

source "$SCRIPT_DIR/context.sh"
source "$SCRIPT_DIR/utils/logger.sh"
source "$SCRIPT_DIR/utils/utils.sh"
source "$SCRIPT_DIR/parser.sh"
source "$SCRIPT_DIR/loader.sh"

main() {
    local config_file="${1:-workspace.yml}"
    
    [[ ! -f "$config_file" ]] && error "Config file not found: $config_file"
    
    load_config "$config_file"
    
    log "Generating cover page..."
    
    local title="${CONFIG_project_title:-Untitled}"
    local subtitle="${CONFIG_project_subtitle:-}"
    local author="${CONFIG_project_author:-Author Name}"
    local category="${CONFIG_project_category:-technical}"
    
    local style="${CONFIG_cover_generated_style:-modern}"
    local title_size="${CONFIG_cover_generated_title_size:-large}"
    local include_subtitle="${CONFIG_cover_generated_include_subtitle:-true}"
    local include_author="${CONFIG_cover_generated_include_author:-true}"
    
    local main_color="primary"
    local accent_color="accent"
    
    if [[ "$category" == "academic" ]]; then
        main_color="black"
        accent_color="gray"
    fi
    
    local font_size="\\Huge"
    case "$title_size" in
        small) font_size="\\huge" ;;
        medium) font_size="\\Huge" ;;
        large) font_size="\\fontsize{48}{54}\\selectfont" ;;
    esac
    
    ensure_dir "frontmatter"
    
    case "$style" in
        modern)
            generate_modern_cover "$title" "$subtitle" "$author" "$main_color" "$accent_color" "$font_size" "$include_subtitle" "$include_author"
            ;;
        classic)
            generate_classic_cover "$title" "$subtitle" "$author" "$font_size" "$include_subtitle" "$include_author"
            ;;
        minimal)
            generate_minimal_cover "$title" "$subtitle" "$author" "$font_size" "$include_subtitle" "$include_author"
            ;;
    esac
    
    success "Generated: frontmatter/cover.tex"
    info "Style: $style"
}

generate_modern_cover() {
    local title="$1"
    local subtitle="$2"
    local author="$3"
    local main_color="$4"
    local accent_color="$5"
    local font_size="$6"
    local include_subtitle="$7"
    local include_author="$8"
    
    cat > "frontmatter/cover.tex" <<EOF
\\begin{titlepage}
\\centering

\\begin{tikzpicture}[remember picture, overlay]
\\shade[top color=$accent_color!5, bottom color=$accent_color!15, middle color=white] 
    (current page.south west) rectangle (current page.north east);

\\foreach \\x in {0,2,...,20} {
    \\foreach \\y in {0,3,...,27} {
        \\node[circle, fill=$accent_color!10, inner sep=0.8pt] 
            at (\$(current page.south west) + (\\x cm, \\y cm)\$) {};
    }
}

\\draw[line width=6pt, color=$main_color, rounded corners=4pt] 
    (\$(current page.north west) + (0.5cm, -0.5cm)\$) -- 
    (\$(current page.north west) + (3cm, -0.5cm)\$) -- 
    (\$(current page.north west) + (3cm, -3cm)\$);

\\draw[line width=6pt, color=$main_color, rounded corners=4pt] 
    (\$(current page.south east) + (-0.5cm, 0.5cm)\$) -- 
    (\$(current page.south east) + (-3cm, 0.5cm)\$) -- 
    (\$(current page.south east) + (-3cm, 3cm)\$);
\\end{tikzpicture}

\\vspace*{5cm}

{$font_size\\bfseries\\color{$main_color}
$title
}

EOF

    if [[ -n "$subtitle" ]] && [[ "$include_subtitle" == "true" ]]; then
        cat >> "frontmatter/cover.tex" <<EOF
\\vspace{1cm}
{\\Large\\color{$accent_color}
$subtitle
}

EOF
    fi

    if [[ "$include_author" == "true" ]]; then
        cat >> "frontmatter/cover.tex" <<EOF
\\vfill

{\\large\\color{$accent_color}
$author
}

\\vspace{2cm}
EOF
    fi

    cat >> "frontmatter/cover.tex" <<EOF

\\end{titlepage}
EOF
}

generate_classic_cover() {
    local title="$1"
    local subtitle="$2"
    local author="$3"
    local font_size="$4"
    local include_subtitle="$5"
    local include_author="$6"
    
    cat > "frontmatter/cover.tex" <<EOF
\\begin{titlepage}
\\centering

\\vspace*{3cm}

{$font_size\\bfseries
$title
}

EOF

    if [[ -n "$subtitle" ]] && [[ "$include_subtitle" == "true" ]]; then
        cat >> "frontmatter/cover.tex" <<EOF
\\vspace{1.5cm}
{\\Large\\itshape
$subtitle
}

EOF
    fi

    cat >> "frontmatter/cover.tex" <<EOF
\\vspace{2cm}

\\rule{0.5\\textwidth}{0.4pt}

\\vfill

EOF

    if [[ "$include_author" == "true" ]]; then
        cat >> "frontmatter/cover.tex" <<EOF
{\\large
$author
}

\\vspace{1cm}
EOF
    fi

    cat >> "frontmatter/cover.tex" <<EOF
{\\large \\today}

\\end{titlepage}
EOF
}

generate_minimal_cover() {
    local title="$1"
    local subtitle="$2"
    local author="$3"
    local font_size="$4"
    local include_subtitle="$5"
    local include_author="$6"
    
    cat > "frontmatter/cover.tex" <<EOF
\\begin{titlepage}
\\centering

\\vspace*{\\fill}

{$font_size\\bfseries
$title
}

EOF

    if [[ -n "$subtitle" ]] && [[ "$include_subtitle" == "true" ]]; then
        cat >> "frontmatter/cover.tex" <<EOF
\\vspace{2cm}
{\\Large
$subtitle
}

EOF
    fi

    if [[ "$include_author" == "true" ]]; then
        cat >> "frontmatter/cover.tex" <<EOF
\\vspace{3cm}
{$author}

EOF
    fi

    cat >> "frontmatter/cover.tex" <<EOF
\\vspace*{\\fill}

\\end{titlepage}
EOF
}

main "$@"