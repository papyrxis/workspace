#!/usr/bin/env bash
# Generate copyright page

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$WORKSPACE_ROOT/scripts/common.sh"

CONFIG_FILE="${1:-workspace.yml}"

[[ ! -f "$CONFIG_FILE" ]] && error "Config file not found: $CONFIG_FILE"

load_config "$CONFIG_FILE"

log "Generating copyright page..."

# Get copyright text
COPYRIGHT_TEXT=$(generate_copyright_text)

TITLE="${CONFIG_project_title:-Untitled}"
AUTHOR="${CONFIG_project_author:-Author Name}"
YEAR="${CONFIG_copyright_year:-auto}"
[[ "$YEAR" == "auto" ]] && YEAR=$(date +%Y)

ensure_dir "frontmatter"

cat > "frontmatter/copyright.tex" <<EOF
\\thispagestyle{empty}

\\vspace*{\\fill}

\\begin{flushleft}
\\textbf{$TITLE}

\\vspace{0.5em}

Written by $AUTHOR

\\vspace{1em}

First Edition

\\vspace{0.5em}

Published: $YEAR

\\vspace{2em}

\\textbf{Copyright Notice}

\\vspace{0.5em}

$COPYRIGHT_TEXT

\\vspace{2em}

\\textbf{Version Information}

\\vspace{0.5em}

Version: \\ProjectVersion \\\\
Built: \\BuildDate

\\vspace{1em}

For the latest version, visit: \\\\
\\url{${CONFIG_project_url:-https://github.com/user/repo}}

\\vspace{1em}

\\textit{Typeset with \\LaTeX{} using Papyrxis workspace.}

\\end{flushleft}

\\clearpage
EOF

log "Generated: frontmatter/copyright.tex"