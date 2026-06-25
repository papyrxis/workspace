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

main() {
    bootstrap_paths
    bootstrap_defaults

    # Parse CLI args (may set SOURCE, ENGINE, etc.)
    parse_build_args "$@"

    # Load workspace.yml — sets SOURCE from build.source if not already set
    load_from_config || true

    # Final SOURCE fallback
    SOURCE="${SOURCE:-main.tex}"

    bootstrap_version
    derive_context

    check_latex "$ENGINE"
    check_bibtex "$BIBTEX" || true

    validate_build_context

    if [[ "$WATCH" == "true" ]]; then
        watch_mode
    else
        build_document
    fi
}

build_document() {
    log "Building: $SOURCE → $OUTPUT_DIR/$PDF_NAME"
    log "Engine: $ENGINE | Version: $VERSION"

    [[ "$CLEAN" == "true" ]] && { log "Cleaning..."; rm -rf "${OUTPUT_DIR:?}"/*; }

    ensure_dir "$OUTPUT_DIR"

    export TEXINPUTS=".:./workspace:"
    export PROJECT_VERSION="$VERSION"
    export BUILD_DATE="$BUILD_DATE"

    run_latex_pass "1/3"

    if needs_bibliography; then
        run_bibliography
        run_latex_pass "2/3"
    fi

    run_latex_pass "3/3"

    check_build_success
}

run_latex_pass() {
    local pass="$1"
    [[ "$QUIET" != "true" ]] && log "Pass $pass..."

    if [[ "$QUIET" == "true" ]]; then
        "$ENGINE" -output-directory="$OUTPUT_DIR" -interaction=nonstopmode "$SOURCE" >/dev/null 2>&1 || true
    else
        "$ENGINE" -output-directory="$OUTPUT_DIR" -interaction=nonstopmode "$SOURCE" || true
    fi
}

needs_bibliography() {
    grep -q '\\bibliography\|\\addbibresource\|\\printbibliography' "$SOURCE"
}

run_bibliography() {
    [[ "$QUIET" != "true" ]] && log "Running $BIBTEX..."
    if [[ "$QUIET" == "true" ]]; then
        (cd "$OUTPUT_DIR" && "$BIBTEX" "$BASENAME" >/dev/null 2>&1) || true
    else
        (cd "$OUTPUT_DIR" && "$BIBTEX" "$BASENAME") || true
    fi
}

check_build_success() {
    if [[ -f "$OUTPUT_DIR/$PDF_NAME" ]]; then
        local size
        size=$(du -h "$OUTPUT_DIR/$PDF_NAME" | cut -f1)
        success "Done: $OUTPUT_DIR/$PDF_NAME ($size)"
        return 0
    else
        error "Build failed. Check $OUTPUT_DIR/${BASENAME}.log"
    fi
}

watch_mode() {
    log "Watch mode — Ctrl+C to stop"
    build_document || true

    local tool
    tool=$(check_watch_tool)

    case "$tool" in
        inotifywait) watch_inotify ;;
        fswatch)     watch_fswatch ;;
        *)           watch_poll ;;
    esac
}

watch_inotify() {
    while true; do
        inotifywait -e modify,create,delete \
            --exclude '\.git|build/|\.swp|\.aux|\.log' \
            -r . 2>/dev/null || true
        log "Change detected, rebuilding..."
        build_document || true
    done
}

watch_fswatch() {
    fswatch -o -e '\.git' -e 'build/' -e '\.swp' -e '\.aux' -e '\.log' . | \
    while read -r; do
        log "Change detected, rebuilding..."
        build_document || true
    done
}

watch_poll() {
    warn "Install inotifywait or fswatch for better watch performance"
    get_sum() {
        find . -type f \( -name "*.tex" -o -name "*.bib" \) \
            -not -path "./build/*" -not -path "./.git/*" \
            -exec md5sum {} \; 2>/dev/null | md5sum | cut -d' ' -f1
    }
    local last; last=$(get_sum)
    while true; do
        sleep 2
        local cur; cur=$(get_sum)
        if [[ "$cur" != "$last" ]]; then
            log "Change detected, rebuilding..."
            build_document || true
            last="$cur"
        fi
    done
}

main "$@"
