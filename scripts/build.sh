#!/usr/bin/env bash
# Build LaTeX document with Papyrxis workspace

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

usage() {
    cat <<EOF
Usage: $0 [OPTIONS] [SOURCE.tex]

Build LaTeX document with proper dependency handling.

OPTIONS:
    -o, --output DIR     Output directory (default: from config or 'build')
    -e, --engine ENGINE  LaTeX engine: pdflatex|xelatex|lualatex (default: from config)
    -b, --bibtex TOOL    Bibliography tool: biber|bibtex (default: from config)
    -c, --clean          Clean build directory before building
    -w, --watch          Watch mode: rebuild on file changes
    -q, --quiet          Suppress non-error output
    -h, --help           Show this help

EXAMPLES:
    $0                    # Build main.tex with config settings
    $0 main.tex          # Build specific file
    $0 -w                # Watch mode
    $0 -c -e xelatex     # Clean build with XeLaTeX

EOF
}

# Defaults
SOURCE="main.tex"
OUTPUT_DIR=""
ENGINE=""
BIBTEX=""
CLEAN=false
WATCH=false
QUIET=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -e|--engine)
            ENGINE="$2"
            shift 2
            ;;
        -b|--bibtex)
            BIBTEX="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -w|--watch)
            WATCH=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *.tex)
            SOURCE="$1"
            shift
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Load config if exists
if [[ -f "workspace.yml" ]]; then
    load_config "workspace.yml" || warn "Failed to load workspace.yml"
    
    # Use config values if not overridden
    [[ -z "$OUTPUT_DIR" ]] && OUTPUT_DIR=$(get_config "build_output_dir" "build")
    [[ -z "$ENGINE" ]] && ENGINE=$(get_config "build_engine" "pdflatex")
    [[ -z "$BIBTEX" ]] && BIBTEX=$(get_config "build_bibtex" "biber")
else
    # Fallback defaults
    [[ -z "$OUTPUT_DIR" ]] && OUTPUT_DIR="build"
    [[ -z "$ENGINE" ]] && ENGINE="pdflatex"
    [[ -z "$BIBTEX" ]] && BIBTEX="biber"
fi

# Validate source
[[ ! -f "$SOURCE" ]] && error "Source file not found: $SOURCE"

BASENAME="${SOURCE%.tex}"
PDF_NAME="${BASENAME}.pdf"

# Check tools
check_latex "$ENGINE"
check_bibtex "$BIBTEX" || true

# Get version info
VERSION=$(get_version)
BUILD_DATE=$(get_build_date)

# Logging wrapper
build_log() {
    $QUIET || log "$@"
}

build_info() {
    $QUIET || info "$@"
}

# Main build function
build_document() {
    build_log "Building $SOURCE with $ENGINE..."
    
    # Clean if requested
    if $CLEAN; then
        build_log "Cleaning build directory..."
        rm -rf "${OUTPUT_DIR:?}"/*
    fi
    
    # Create output directory
    ensure_dir "$OUTPUT_DIR"
    
    # Set TEXINPUTS to include current directory
    export TEXINPUTS=".:./workspace:"
    
    # Export version variables for LaTeX
    export PROJECT_VERSION="$VERSION"
    export BUILD_DATE="$BUILD_DATE"
    
    build_log "Version: $VERSION"
    build_log "Build date: $BUILD_DATE"
    
    # First pass
    build_log "Pass 1/3: Initial compilation..."
    if $QUIET; then
        $ENGINE -output-directory="$OUTPUT_DIR" -interaction=nonstopmode "$SOURCE" >/dev/null 2>&1 || true
    else
        $ENGINE -output-directory="$OUTPUT_DIR" -interaction=nonstopmode "$SOURCE" || true
    fi
    
    # Check for bibliography
    local needs_bib=false
    if grep -q '\\bibliography\|\\addbibresource\|\\printbibliography' "$SOURCE"; then
        needs_bib=true
    fi
    
    # Run bibliography if needed
    if $needs_bib; then
        build_log "Running $BIBTEX..."
        if $QUIET; then
            (cd "$OUTPUT_DIR" && $BIBTEX "$BASENAME" >/dev/null 2>&1) || true
        else
            (cd "$OUTPUT_DIR" && $BIBTEX "$BASENAME") || true
        fi
    fi
    
    # Second pass (for citations)
    if $needs_bib; then
        build_log "Pass 2/3: Processing citations..."
        if $QUIET; then
            $ENGINE -output-directory="$OUTPUT_DIR" -interaction=nonstopmode "$SOURCE" >/dev/null 2>&1 || true
        else
            $ENGINE -output-directory="$OUTPUT_DIR" -interaction=nonstopmode "$SOURCE" || true
        fi
    fi
    
    # Final pass (for references)
    build_log "Pass 3/3: Final compilation..."
    if $QUIET; then
        $ENGINE -output-directory="$OUTPUT_DIR" -interaction=nonstopmode "$SOURCE" >/dev/null 2>&1
    else
        $ENGINE -output-directory="$OUTPUT_DIR" -interaction=nonstopmode "$SOURCE"
    fi
    
    # Check for errors
    if [[ -f "$OUTPUT_DIR/$PDF_NAME" ]]; then
        build_log "✓ Build successful!"
        build_info "Output: $OUTPUT_DIR/$PDF_NAME"
        
        # Show file size
        local size
        size=$(du -h "$OUTPUT_DIR/$PDF_NAME" | cut -f1)
        build_info "Size: $size"
        
        return 0
    else
        error "Build failed. Check $OUTPUT_DIR/${BASENAME}.log for details."
    fi
}

# Watch mode function
watch_mode() {
    build_log "Entering watch mode (Ctrl+C to stop)..."
    build_log "Watching: $SOURCE and related files"
    
    # Initial build
    build_document
    
    # Check for inotifywait (Linux) or fswatch (macOS)
    if command_exists inotifywait; then
        build_log "Using inotifywait for file monitoring"
        while true; do
            # Watch .tex files and figures
            inotifywait -e modify -e create -e delete \
                --exclude '\.git|build/|\.swp|\.aux|\.log' \
                -r . 2>/dev/null || true
            
            build_log "Change detected, rebuilding..."
            build_document || true
            build_log "Waiting for changes..."
        done
    elif command_exists fswatch; then
        build_log "Using fswatch for file monitoring"
        fswatch -o -e '\.git' -e 'build/' -e '\.swp' -e '\.aux' -e '\.log' . | \
        while read -r; do
            build_log "Change detected, rebuilding..."
            build_document || true
            build_log "Waiting for changes..."
        done
    else
        # Fallback to polling
        build_log "Using polling for file monitoring (install inotifywait or fswatch for better performance)"
        
        get_checksum() {
            find . -type f \( -name "*.tex" -o -name "*.bib" \) \
                -not -path "./build/*" -not -path "./.git/*" \
                -exec md5sum {} \; 2>/dev/null | md5sum | cut -d' ' -f1
        }
        
        LAST_HASH=$(get_checksum)
        
        while true; do
            sleep 2
            CURRENT_HASH=$(get_checksum)
            
            if [[ "$CURRENT_HASH" != "$LAST_HASH" ]]; then
                build_log "Change detected, rebuilding..."
                build_document || true
                LAST_HASH=$(get_checksum)
                build_log "Waiting for changes..."
            fi
        done
    fi
}

# Main execution
if $WATCH; then
    watch_mode
else
    build_document
fi