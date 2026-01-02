#!/usr/bin/env bash
# Generate frontmatter files from templates

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$WORKSPACE_ROOT/scripts/common.sh"

usage() {
    cat <<EOF
Usage: $0 -t TYPE -f FILE [CONFIG_FILE]

Generate frontmatter file from template.

OPTIONS:
    -t, --type TYPE       Frontmatter type: preface|acknowledgments|introduction
    -f, --force           Force overwrite existing file
    -h, --help           Show this help

ARGUMENTS:
    CONFIG_FILE          Configuration file (default: workspace.yml)

EXAMPLES:
    $0 -t preface
    $0 -t introduction -f

EOF
}

TYPE=""
FORCE=false
CONFIG_FILE="workspace.yml"

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            TYPE="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            CONFIG_FILE="$1"
            shift
            ;;
    esac
done

[[ -z "$TYPE" ]] && error "Frontmatter type required (-t)"
[[ ! -f "$CONFIG_FILE" ]] && error "Config file not found: $CONFIG_FILE"

# Load config
load_config "$CONFIG_FILE"

TITLE="${CONFIG_project_title:-Untitled}"
AUTHOR="${CONFIG_project_author:-Author Name}"
EMAIL="${CONFIG_project_email:-}"
URL="${CONFIG_project_url:-}"
SUBJECT="${CONFIG_project_subject:-}"
KEYWORDS="${CONFIG_project_keywords:-}"

# Check template
TEMPLATE_FILE="$WORKSPACE_ROOT/template/books/frontmatter/${TYPE}.tex"
[[ ! -f "$TEMPLATE_FILE" ]] && error "Template not found: $TEMPLATE_FILE"

# Output file
OUTPUT_FILE="frontmatter/${TYPE}.tex"

# Check if exists
if [[ -f "$OUTPUT_FILE" ]] && ! $FORCE; then
    log "File already exists: $OUTPUT_FILE (use -f to overwrite)"
    exit 0
fi

log "Generating $TYPE from template..."

# Ensure directory
ensure_dir "frontmatter"

# Process template with substitutions
sed -e "s|{{TITLE}}|$TITLE|g" \
    -e "s|{{AUTHOR}}|$AUTHOR|g" \
    -e "s|{{EMAIL}}|$EMAIL|g" \
    -e "s|{{URL}}|$URL|g" \
    -e "s|{{SUBJECT}}|$SUBJECT|g" \
    -e "s|{{KEYWORDS}}|$KEYWORDS|g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

log "✓ Generated: $OUTPUT_FILE"