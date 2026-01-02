#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"

source "$SCRIPT_DIR/context.sh"
source "$SCRIPT_DIR/utils/logger.sh"
source "$SCRIPT_DIR/utils/utils.sh"
source "$SCRIPT_DIR/utils/messages_builder.sh"
source "$SCRIPT_DIR/parser.sh"
source "$SCRIPT_DIR/loader.sh"
source "$SCRIPT_DIR/args.sh"
source "$SCRIPT_DIR/bootstrap.sh"

main() {
    bootstrap_paths
    
    local result
    result=$(parse_frontmatter_args "$@")
    
    local front_type="${result%%|*}"
    local force="${result##*|}"
    
    [[ -z "$front_type" ]] && error "Frontmatter type required (-t)"
    [[ ! -f "$CONFIG_FILE" ]] && error "Config file not found: $CONFIG_FILE"
    
    load_config "$CONFIG_FILE"
    
    local template_file="$WORKSPACE_ROOT/template/books/frontmatter/${front_type}.tex"
    [[ ! -f "$template_file" ]] && error "Template not found: $template_file"
    
    local output_file="frontmatter/${front_type}.tex"
    
    if [[ -f "$output_file" ]] && [[ "$force" != "true" ]]; then
        log "File already exists: $output_file (use -f to overwrite)"
        exit 0
    fi
    
    log "Generating $front_type from template..."
    
    ensure_dir "frontmatter"
    
    local title="${CONFIG_project_title:-Untitled}"
    local author="${CONFIG_project_author:-Author Name}"
    local email="${CONFIG_project_email:-}"
    local url="${CONFIG_project_url:-}"
    local subject="${CONFIG_project_subject:-}"
    local keywords="${CONFIG_project_keywords:-}"
    
    sed -e "s|{{TITLE}}|$title|g" \
        -e "s|{{AUTHOR}}|$author|g" \
        -e "s|{{EMAIL}}|$email|g" \
        -e "s|{{URL}}|$url|g" \
        -e "s|{{SUBJECT}}|$subject|g" \
        -e "s|{{KEYWORDS}}|$keywords|g" \
        "$template_file" > "$output_file"
    
    success "Generated: $output_file"
}

main "$@"