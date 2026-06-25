#!/usr/bin/env bash

set -euo pipefail

parse_build_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--output)   OUTPUT_DIR="$2"; shift 2 ;;
            -e|--engine)   ENGINE="$2";     shift 2 ;;
            -b|--bibtex)   BIBTEX="$2";     shift 2 ;;
            -c|--clean)    CLEAN=true;       shift ;;
            -w|--watch)    WATCH=true;       shift ;;
            -q|--quiet)    QUIET=true;       shift ;;
            -s|--source)   SOURCE="$2";      shift 2 ;;
            --source=*)    SOURCE="${1#*=}"; shift ;;
            *.tex)         SOURCE="$1";      shift ;;
            -h|--help)     build_usage; exit 0 ;;
            *) error "Unknown option: $1" ;;
        esac
    done
}

parse_part_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--number) PART="$2";        shift 2 ;;
            -t|--title)  TITLE="$2";       shift 2 ;;
            -d|--desc)   DESCRIPTION="$2"; shift 2 ;;
            -h|--help)   part_usage; exit 0 ;;
            *) error "Unknown option: $1" ;;
        esac
    done
}

parse_chapter_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--part)    PART="$2";        shift 2 ;;
            -c|--chapter) CHAPTER="$2";     shift 2 ;;
            -t|--title)   TITLE="$2";       shift 2 ;;
            -d|--desc)    DESCRIPTION="$2"; shift 2 ;;
            -s|--sections) SECTIONS="$2";   shift 2 ;;
            -h|--help)    chapter_usage; exit 0 ;;
            *) error "Unknown option: $1" ;;
        esac
    done
}

parse_frontmatter_args() {
    local front_type=""
    local force=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type)  front_type="$2"; shift 2 ;;
            -f|--force) force=true;       shift ;;
            -h|--help)  frontmatter_usage; exit 0 ;;
            *)          CONFIG_FILE="$1"; shift ;;
        esac
    done

    echo "$front_type|$force"
}

export -f parse_build_args parse_part_args parse_chapter_args parse_frontmatter_args
