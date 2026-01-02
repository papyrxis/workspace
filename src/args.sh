#!/usr/bin/env bash

set -euo pipefail

parse_init_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type)
                TYPE="$2"
                shift 2
                ;;
            -c|--category)
                CATEGORY="$2"
                shift 2
                ;;
            -n|--name)
                NAME="$2"
                shift 2
                ;;
            --title)
                TITLE="$2"
                shift 2
                ;;
            --author)
                AUTHOR="$2"
                shift 2
                ;;
            --email)
                EMAIL="$2"
                shift 2
                ;;
            --url)
                URL="$2"
                shift 2
                ;;
            --subtitle)
                SUBTITLE="$2"
                shift 2
                ;;
            --subject)
                SUBJECT="$2"
                shift 2
                ;;
            --keywords)
                KEYWORDS="$2"
                shift 2
                ;;
            -d|--dir)
                TARGET_DIR="$2"
                shift 2
                ;;
            --interactive)
                INTERACTIVE=true
                shift
                ;;
            -h|--help)
                init_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

parse_build_args() {
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
                build_usage
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
}

parse_update_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                FORCE=true
                shift
                ;;
            -b|--backup)
                BACKUP=true
                shift
                ;;
            -c|--check)
                CHECK_ONLY=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                update_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

parse_part_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--number)
                PART="$2"
                shift 2
                ;;
            -t|--title)
                TITLE="$2"
                shift 2
                ;;
            -d|--desc)
                DESCRIPTION="$2"
                shift 2
                ;;
            -h|--help)
                part_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

parse_chapter_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--part)
                PART="$2"
                shift 2
                ;;
            -c|--chapter)
                CHAPTER="$2"
                shift 2
                ;;
            -t|--title)
                TITLE="$2"
                shift 2
                ;;
            -d|--desc)
                DESCRIPTION="$2"
                shift 2
                ;;
            -s|--sections)
                SECTIONS="$2"
                shift 2
                ;;
            -h|--help)
                chapter_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

parse_frontmatter_args() {
    local front_type=""
    local force=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type)
                front_type="$2"
                shift 2
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -h|--help)
                frontmatter_usage
                exit 0
                ;;
            *)
                CONFIG_FILE="$1"
                shift
                ;;
        esac
    done
    
    echo "$front_type|$force"
}

export -f parse_init_args parse_build_args parse_update_args
export -f parse_part_args parse_chapter_args parse_frontmatter_args