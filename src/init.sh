#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/context.sh"
source "$SCRIPT_DIR/utils/logger.sh"
source "$SCRIPT_DIR/utils/utils.sh"
source "$SCRIPT_DIR/utils/gitinfo.sh"
source "$SCRIPT_DIR/parser.sh"
source "$SCRIPT_DIR/loader.sh"
source "$SCRIPT_DIR/checker.sh"
source "$SCRIPT_DIR/bootstrap.sh"
source "$SCRIPT_DIR/setup/workspace.sh"

main() {
    bootstrap_paths
    bootstrap_defaults
    bootstrap_git_info
    bootstrap_version

    interactive_init

    log "Initializing $TYPE project: $TITLE"
    log "Author: $AUTHOR"
    [[ -n "$URL" ]] && log "URL: $URL"

    init_workspace

    success "Project ready."
    echo ""
    echo "  Next steps:"
    echo "    make sync   — generate .pxis/ from workspace.yml"
    echo "    make        — build your document"
    echo "    make watch  — auto-rebuild on save"
    echo ""
}

interactive_init() {
    echo ""
    echo "  ─────────────────────────────────"
    echo "   Workspace Init"
    echo "  ─────────────────────────────────"
    echo ""

    # Type
    echo "  What are you writing?"
    echo "    1) book"
    echo "    2) article / paper"
    printf "  Choice [1]: "
    read -r choice
    case "${choice:-1}" in
        2|article|paper) TYPE="article" ;;
        *) TYPE="book" ;;
    esac
    echo ""

    # Title
    local default_title="${TITLE:-Untitled}"
    printf "  Title [%s]: " "$default_title"
    read -r input
    TITLE="${input:-$default_title}"

    # Author
    local default_author="${AUTHOR:-Author Name}"
    printf "  Author [%s]: " "$default_author"
    read -r input
    AUTHOR="${input:-$default_author}"

    # Email (optional)
    local default_email="${EMAIL:-}"
    if [[ -n "$default_email" ]]; then
        printf "  Email [%s]: " "$default_email"
    else
        printf "  Email (optional): "
    fi
    read -r input
    EMAIL="${input:-$default_email}"

    # URL (optional)
    local default_url="${URL:-}"
    if [[ -n "$default_url" ]]; then
        printf "  Repository URL [%s]: " "$default_url"
    else
        printf "  Repository URL (optional): "
    fi
    read -r input
    URL="${input:-$default_url}"

    # Main source file
    if [[ "$TYPE" == "book" ]]; then
        printf "  Main .tex filename [main.tex]: "
        read -r input
        local src="${input:-main.tex}"
        src="${src%.tex}.tex"
        SOURCE="$src"
    else
        SOURCE="main.tex"
    fi

    echo ""
}

main "$@"
