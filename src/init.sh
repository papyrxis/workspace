#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/context.sh"
source "$SCRIPT_DIR/utils/logger.sh"
source "$SCRIPT_DIR/utils/utils.sh"
source "$SCRIPT_DIR/utils/gitinfo.sh"
source "$SCRIPT_DIR/utils/messages_builder.sh"
source "$SCRIPT_DIR/parser.sh"
source "$SCRIPT_DIR/loader.sh"
source "$SCRIPT_DIR/checker.sh"
source "$SCRIPT_DIR/args.sh"
source "$SCRIPT_DIR/bootstrap.sh"
source "$SCRIPT_DIR/setup/workspace.sh"

main() {
    bootstrap_paths
    bootstrap_defaults
    
    parse_init_args "$@"
    
    bootstrap_git_info
    bootstrap_version
    
    if [[ "$INTERACTIVE" == "true" ]]; then
        interactive_mode
    fi
    
    validate_init_context
    
    log "Initializing $TYPE project: $NAME"
    log "Category: $CATEGORY"
    log "Author: $AUTHOR"
    [[ -n "$EMAIL" ]] && log "Email: $EMAIL"
    log "URL: $URL"
    
    init_workspace
    
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
}

interactive_mode() {
    read -p "Project name [$NAME]: " input && [[ -n "$input" ]] && NAME="$input"
    read -p "Document title [$TITLE]: " input && [[ -n "$input" ]] && TITLE="$input"
    read -p "Author name [$AUTHOR]: " input && [[ -n "$input" ]] && AUTHOR="$input"
    read -p "Author email [$EMAIL]: " input && [[ -n "$input" ]] && EMAIL="$input"
    read -p "Project URL [$URL]: " input && [[ -n "$input" ]] && URL="$input"
    read -p "Category [$CATEGORY]: " input && [[ -n "$input" ]] && CATEGORY="$input"
}

main "$@"