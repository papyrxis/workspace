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
    
    log "Generating copyright page..."
    
    local copyright_text
    copyright_text=$(generate_copyright_text)
    local title="${CONFIG_project_title:-Untitled}"
    local author="${CONFIG_project_author:-Author Name}"
    local year="${CONFIG_copyright_year:-auto}"
    local url="${CONFIG_project_url:-}"
    
    [[ "$year" == "auto" ]] && year=$(date +%Y)
    
    ensure_dir "frontmatter"
    
    cat > "frontmatter/copyright.tex" <<EOF
\\thispagestyle{empty}

\\vspace*{\\fill}

\\begin{flushleft}
\\textbf{$title}

\\vspace{0.5em}

Written by $author

\\vspace{1em}

First Edition

\\vspace{0.5em}

Published: $year

\\vspace{2em}

\\textbf{Copyright Notice}

\\vspace{0.5em}

$copyright_text

\\vspace{2em}

\\textbf{Version Information}

\\vspace{0.5em}

Version: \\ProjectVersion \\\\
Built: \\BuildDate

\\vspace{1em}

For the latest version, visit: \\\\
\\url{$url}

\\vspace{1em}

\\textit{Typeset with \\LaTeX{} using Papyrxis workspace.}

\\end{flushleft}

\\clearpage
EOF
    
    success "Generated: frontmatter/copyright.tex"
}

main "$@"