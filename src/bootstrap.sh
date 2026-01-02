#!/usr/bin/env bash

set -euo pipefail

bootstrap_paths() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"
}

bootstrap_defaults() {
    CATEGORY="${CATEGORY:-technical}"
    
    TARGET_DIR="${TARGET_DIR:-.}"
    WORKSPACE_FILE="${WORKSPACE_FILE:-$TARGET_DIR/workspace.yml}"
    
    SOURCE="${SOURCE:-main.tex}"
    
    OUTPUT_DIR="${OUTPUT_DIR:-build}"
    ENGINE="${ENGINE:-pdflatex}"
    BIBTEX="${BIBTEX:-biber}"
    
    CONFIG_FILE="${CONFIG_FILE:-workspace.yml}"
}

bootstrap_git_info() {
    detect_git_info
   
    [[ -z "$NAME" ]] && NAME=$(basename "$(realpath "$TARGET_DIR")")
    [[ -z "$TITLE" ]] && TITLE="$NAME"
    [[ -z "$AUTHOR" ]] && AUTHOR="Author Name"
    [[ -z "$URL" ]] && URL="https://github.com/user/$NAME"
    return 0
}

bootstrap_version() {
    VERSION=$(get_version)
    BUILD_DATE=$(get_build_date)
}

derive_context() {
    BASENAME="${SOURCE%.tex}"
    PDF_NAME="${BASENAME}.pdf"
    
    PROJECT_TYPE="${TYPE:-book}"
    PROJECT_CATEGORY="${CATEGORY:-technical}"
    
    OVERRIDE_DIR="${CONFIG_overrides_components_dir:-configs}"
    
    if [[ -n "${PART:-}" ]]; then
        PADDED_PART=$(pad_number "$PART")
        PART_DIR="parts/part$PADDED_PART"
    fi
    
    if [[ -n "${CHAPTER:-}" ]]; then
        PADDED_CHAPTER=$(pad_number "$CHAPTER")
        CHAPTER_DIR="$PART_DIR/chapter$PADDED_CHAPTER"
        CHAPTER_FILE="$CHAPTER_DIR/chapter$PADDED_CHAPTER.tex"
    fi
}

validate_init_context() {
    [[ -z "$TYPE" ]] && error "Project type required (-t book|article)"
    
    case "$TYPE" in
        book|article) ;;
        *) error "Invalid type: $TYPE (must be book or article)" ;;
    esac
    
    case "$CATEGORY" in
        technical|academic) ;;
        *) error "Invalid category: $CATEGORY (must be technical or academic)" ;;
    esac
}

validate_build_context() {
    check_workspace_file || error "No workspace.yml found. Run init.sh first."
    check_file_exists "$SOURCE" || error "Source file not found: $SOURCE"
    
    case "$ENGINE" in
        pdflatex|xelatex|lualatex) ;;
        *) error "Invalid LaTeX engine: $ENGINE" ;;
    esac
}

validate_part_context() {
    [[ -z "$PART" ]] && error "Part number required (-n)"
    [[ -z "$TITLE" ]] && error "Part title required (-t)"
}

validate_chapter_context() {
    [[ -z "$PART" ]] && error "Part number required (-p)"
    [[ -z "$CHAPTER" ]] && error "Chapter number required (-c)"
    [[ -z "$TITLE" ]] && error "Chapter title required (-t)"
    
    check_dir_exists "$PART_DIR" || error "Part directory not found: $PART_DIR"
    check_dir_exists "$CHAPTER_DIR" && error "Chapter already exists: $CHAPTER_DIR"
}

export -f bootstrap_paths bootstrap_defaults bootstrap_git_info bootstrap_version
export -f derive_context validate_init_context validate_build_context
export -f validate_part_context validate_chapter_context