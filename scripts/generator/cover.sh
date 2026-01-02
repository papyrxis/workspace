#!/usr/bin/env bash
# Generate cover page

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$WORKSPACE_ROOT/scripts/common.sh"

CONFIG_FILE="${1:-workspace.yml}"

[[ ! -f "$CONFIG_FILE" ]] && error "Config file not found: $CONFIG_FILE"

load_config "$CONFIG_FILE"

log "Generating cover page..."

TITLE="${CONFIG_project_title:-Untitled}"
SUBTITLE="${CONFIG_project_subtitle:-}"
AUTHOR="${CONFIG_project_author:-Author Name}"
CATEGORY="${CONFIG_project_category:-technical}"

STYLE="${CONFIG_cover_generated_style:-modern}"
TITLE_SIZE="${CONFIG_cover_generated_title_size:-large}"
INCLUDE_SUBTITLE="${CONFIG_cover_generated_include_subtitle:-true}"
INCLUDE_AUTHOR="${CONFIG_cover_generated_include_author:-true}"

ensure_dir "frontmatter"

# Determine color based on category
if [[ "$CATEGORY" == "academic" ]]; then
    MAIN_COLOR="black"
    ACCENT_COLOR="gray"
else
    MAIN_COLOR="primary"
    ACCENT_COLOR="accent"
fi

# Title size mapping
case "$TITLE_SIZE" in
    small) FONT_SIZE="\\huge" ;;
    medium) FONT_SIZE="\\Huge" ;;
    large) FONT_SIZE="\\fontsize{48}{54}\\selectfont" ;;
    *) FONT_SIZE="\\Huge" ;;
esac

case "$STYLE" in
    modern)
        cat > "frontmatter/cover.tex" <<EOF
\\begin{titlepage}
\\centering

% Modern geometric background
\\begin{tikzpicture}[remember picture, overlay]
\\shade[top color=$ACCENT_COLOR!5, bottom color=$ACCENT_COLOR!15, middle color=white] 
    (current page.south west) rectangle (current page.north east);

% Decorative elements
\\foreach \\x in {0,2,...,20} {
    \\foreach \\y in {0,3,...,27} {
        \\node[circle, fill=$ACCENT_COLOR!10, inner sep=0.8pt] 
            at (\$(current page.south west) + (\\x cm, \\y cm)\$) {};
    }
}

% Corner accents
\\draw[line width=6pt, color=$MAIN_COLOR, rounded corners=4pt] 
    (\$(current page.north west) + (0.5cm, -0.5cm)\$) -- 
    (\$(current page.north west) + (3cm, -0.5cm)\$) -- 
    (\$(current page.north west) + (3cm, -3cm)\$);

\\draw[line width=6pt, color=$MAIN_COLOR, rounded corners=4pt] 
    (\$(current page.south east) + (-0.5cm, 0.5cm)\$) -- 
    (\$(current page.south east) + (-3cm, 0.5cm)\$) -- 
    (\$(current page.south east) + (-3cm, 3cm)\$);
\\end{tikzpicture}

\\vspace*{5cm}

% Title
{$FONT_SIZE\\bfseries\\color{$MAIN_COLOR}
$TITLE
}

EOF

        if [[ -n "$SUBTITLE" ]] && [[ "$INCLUDE_SUBTITLE" == "true" ]]; then
            cat >> "frontmatter/cover.tex" <<EOF
\\vspace{1cm}
{\\Large\\color{$ACCENT_COLOR}
$SUBTITLE
}

EOF
        fi

        if [[ "$INCLUDE_AUTHOR" == "true" ]]; then
            cat >> "frontmatter/cover.tex" <<EOF
\\vfill

{\\large\\color{$ACCENT_COLOR}
$AUTHOR
}

\\vspace{2cm}
EOF
        fi

        cat >> "frontmatter/cover.tex" <<EOF

\\end{titlepage}
EOF
        ;;
        
    classic)
        cat > "frontmatter/cover.tex" <<EOF
\\begin{titlepage}
\\centering

\\vspace*{3cm}

% Classic title
{$FONT_SIZE\\bfseries
$TITLE
}

EOF

        if [[ -n "$SUBTITLE" ]] && [[ "$INCLUDE_SUBTITLE" == "true" ]]; then
            cat >> "frontmatter/cover.tex" <<EOF
\\vspace{1.5cm}
{\\Large\\itshape
$SUBTITLE
}

EOF
        fi

        cat >> "frontmatter/cover.tex" <<EOF
\\vspace{2cm}

\\rule{0.5\\textwidth}{0.4pt}

\\vfill

EOF

        if [[ "$INCLUDE_AUTHOR" == "true" ]]; then
            cat >> "frontmatter/cover.tex" <<EOF
{\\large
$AUTHOR
}

\\vspace{1cm}
EOF
        fi

        cat >> "frontmatter/cover.tex" <<EOF
{\\large \\today}

\\end{titlepage}
EOF
        ;;
        
    minimal)
        cat > "frontmatter/cover.tex" <<EOF
\\begin{titlepage}
\\centering

\\vspace*{\\fill}

% Minimal title
{$FONT_SIZE\\bfseries
$TITLE
}

EOF

        if [[ -n "$SUBTITLE" ]] && [[ "$INCLUDE_SUBTITLE" == "true" ]]; then
            cat >> "frontmatter/cover.tex" <<EOF
\\vspace{2cm}
{\\Large
$SUBTITLE
}

EOF
        fi

        if [[ "$INCLUDE_AUTHOR" == "true" ]]; then
            cat >> "frontmatter/cover.tex" <<EOF
\\vspace{3cm}
{$AUTHOR}

EOF
        fi

        cat >> "frontmatter/cover.tex" <<EOF
\\vspace*{\\fill}

\\end{titlepage}
EOF
        ;;
esac

log "Generated: frontmatter/cover.tex"
info "Style: $STYLE"