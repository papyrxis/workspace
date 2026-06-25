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
    [[ ! -f "$config_file" ]] && error "Config not found: $config_file"
    load_config "$config_file"

    local title="${CONFIG_project_title:-Untitled}"
    local author="${CONFIG_project_author:-Author}"
    local url="${CONFIG_project_url:-}"
    local year="${CONFIG_copyright_year:-auto}"
    local type="${CONFIG_copyright_type:-cc-by-sa}"

    [[ "$year" == "auto" ]] && year=$(date +%Y)

    ensure_dir "frontmatter"

    local license_text
    license_text=$(make_license_text "$type" "$year" "$author")

    log "Generating copyright page..."

    cat > "frontmatter/copyright.tex" <<EOF
\\thispagestyle{empty}

\\begin{tikzpicture}[remember picture, overlay]
  \\draw[line width=2pt, color=accent!25, rotate around={45:(current page.north west)},
    shift={(current page.north west)}] (0.4cm,-0.4cm) -- (2.5cm,-0.4cm);
  \\draw[line width=2pt, color=accent!25, rotate around={45:(current page.south east)},
    shift={(current page.south east)}] (-0.4cm,0.4cm) -- (-2.5cm,0.4cm);
\\end{tikzpicture}

\\begin{center}
  \\vspace*{1.5cm}
  {\\Large\\bfseries\\textcolor{accent}{$title}}\\\\[0.3em]
  \\rule{0.45\\textwidth}{0.4pt}
  \\vspace{1em}
\\end{center}

\\begin{flushleft}
{\\small\\linespread{1.1}\\selectfont

\\textbf{Author:} $author\\\\
$(if [[ -n "$url" ]]; then echo "\\\\textbf{Repository:} \\\\url{$url}\\\\\\\\"; fi)

\\vspace{0.8em}

$license_text

\\vspace{0.8em}

\\textbf{Version:} \\ProjectVersion\\\\
\\textbf{Built:} \\BuildDate

$(if [[ -n "$url" ]]; then
cat <<INNER
\\vspace{0.8em}

For updates and errata, see \\url{$url}
INNER
fi)

\\vspace{0.8em}

\\textit{Typeset with \\LaTeX{} using Papyrxis.}

}
\\end{flushleft}

\\clearpage
EOF

    success "Generated: frontmatter/copyright.tex"
}

make_license_text() {
    local type="$1" year="$2" holder="$3"
    case "$type" in
        cc-by-sa)
            cat <<EOF
\\textbf{Copyright \\textcopyright\\ $year $holder.}
This work is licensed under CC BY-SA 4.0.
You may share and adapt it for any purpose, provided you give credit,
link to the license, note changes, and distribute derivatives
under the same terms. \\url{https://creativecommons.org/licenses/by-sa/4.0/}
EOF
            ;;
        cc-by)
            cat <<EOF
\\textbf{Copyright \\textcopyright\\ $year $holder.}
Licensed under CC BY 4.0. \\url{https://creativecommons.org/licenses/by/4.0/}
EOF
            ;;
        cc-by-nc)
            cat <<EOF
\\textbf{Copyright \\textcopyright\\ $year $holder.}
Licensed under CC BY-NC 4.0 (non-commercial).
\\url{https://creativecommons.org/licenses/by-nc/4.0/}
EOF
            ;;
        mit)
            cat <<EOF
\\textbf{Copyright \\textcopyright\\ $year $holder.}
Released under the MIT License. Permission is granted to use, copy, modify,
and distribute this work, provided the above copyright notice is retained.
EOF
            ;;
        none)
            echo "\\textbf{Copyright \\textcopyright\\ $year $holder.} All rights reserved."
            ;;
        *)
            echo "\\textbf{Copyright \\textcopyright\\ $year $holder.}"
            ;;
    esac
}

main "$@"
