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
    
    parse_build_args "$@"
    
    load_from_config || true
    
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
    log "Building $SOURCE with $ENGINE..."
    
    if [[ "$CLEAN" == "true" ]]; then
        log "Cleaning build directory..."
        rm -rf "${OUTPUT_DIR:?}"/*
    fi
    
    ensure_dir "$OUTPUT_DIR"
    
    export TEXINPUTS=".:./workspace:"
    export PROJECT_VERSION="$VERSION"
    export BUILD_DATE="$BUILD_DATE"
    
    if [[ "$QUIET" != "true" ]]; then
        log "Version: $VERSION"
        log "Build date: $BUILD_DATE"
    fi
    
    run_latex_pass "1/3: Initial compilation"
    
    if needs_bibliography; then
        run_bibliography
        run_latex_pass "2/3: Processing citations"
    fi
    
    run_latex_pass "3/3: Final compilation"
    
    check_build_success
}

run_latex_pass() {
    local pass_name="$1"
    
    [[ "$QUIET" != "true" ]] && log "Pass $pass_name..."
    
    local output_redirect=""
    if [[ "$QUIET" == "true" ]]; then
        output_redirect=">/dev/null 2>&1"
    fi
    
    eval "$ENGINE -output-directory='$OUTPUT_DIR' -interaction=nonstopmode '$SOURCE' $output_redirect" || true
}

needs_bibliography() {
    grep -q '\\bibliography\|\\addbibresource\|\\printbibliography' "$SOURCE"
}

run_bibliography() {
    [[ "$QUIET" != "true" ]] && log "Running $BIBTEX..."
    
    local output_redirect=""
    if [[ "$QUIET" == "true" ]]; then
        output_redirect=">/dev/null 2>&1"
    fi
    
    eval "(cd '$OUTPUT_DIR' && $BIBTEX '$BASENAME' $output_redirect)" || true
}

check_build_success() {
    if [[ -f "$OUTPUT_DIR/$PDF_NAME" ]]; then
        success "Build successful!"
        
        if [[ "$QUIET" != "true" ]]; then
            info "Output: $OUTPUT_DIR/$PDF_NAME"
            
            local size
            size=$(du -h "$OUTPUT_DIR/$PDF_NAME" | cut -f1)
            info "Size: $size"
        fi
        
        return 0
    else
        error "Build failed. Check $OUTPUT_DIR/${BASENAME}.log for details."
    fi
}

watch_mode() {
    log "Entering watch mode (Ctrl+C to stop)..."
    log "Watching: $SOURCE and related files"
    
    build_document || true
    
    local watch_tool
    watch_tool=$(check_watch_tool)
    
    case "$watch_tool" in
        inotifywait)
            watch_with_inotifywait
            ;;
        fswatch)
            watch_with_fswatch
            ;;
        polling)
            watch_with_polling
            ;;
    esac
}

watch_with_inotifywait() {
    log "Using inotifywait for file monitoring"
    
    while true; do
        inotifywait -e modify -e create -e delete \
            --exclude '\.git|build/|\.swp|\.aux|\.log' \
            -r . 2>/dev/null || true
        
        log "Change detected, rebuilding..."
        build_document || true
        log "Waiting for changes..."
    done
}

watch_with_fswatch() {
    log "Using fswatch for file monitoring"
    
    fswatch -o -e '\.git' -e 'build/' -e '\.swp' -e '\.aux' -e '\.log' . | \
    while read -r; do
        log "Change detected, rebuilding..."
        build_document || true
        log "Waiting for changes..."
    done
}

watch_with_polling() {
    log "Using polling for file monitoring"
    warn "Install inotifywait or fswatch for better performance"
    
    get_checksum() {
        find . -type f \( -name "*.tex" -o -name "*.bib" \) \
            -not -path "./build/*" -not -path "./.git/*" \
            -exec md5sum {} \; 2>/dev/null | md5sum | cut -d' ' -f1
    }
    
    local last_hash
    last_hash=$(get_checksum)
    
    while true; do
        sleep 2
        local current_hash
        current_hash=$(get_checksum)
        
        if [[ "$current_hash" != "$last_hash" ]]; then
            log "Change detected, rebuilding..."
            build_document || true
            last_hash=$(get_checksum)
            log "Waiting for changes..."
        fi
    done
}

main "$@"