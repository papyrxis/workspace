#!/usr/bin/env bash

set -euo pipefail

declare -g WORKSPACE_ROOT=""

declare -g TYPE=""
declare -g CATEGORY=""
declare -g NAME=""
declare -g TITLE=""
declare -g AUTHOR=""
declare -g EMAIL=""
declare -g URL=""
declare -g SUBTITLE=""
declare -g SUBJECT=""
declare -g KEYWORDS=""

declare -g TARGET_DIR=""
declare -g WORKSPACE_FILE=""

declare -g SOURCE=""
declare -g OUTPUT_DIR=""
declare -g ENGINE=""
declare -g BIBTEX=""

declare -g CLEAN=false
declare -g WATCH=false
declare -g QUIET=false
declare -g INTERACTIVE=false
declare -g FORCE=false
declare -g BACKUP=false
declare -g CHECK_ONLY=false
declare -g VERBOSE=false

declare -g BASENAME=""
declare -g PDF_NAME=""

declare -g PROJECT_TYPE=""
declare -g PROJECT_CATEGORY=""
declare -g OVERRIDE_DIR=""

declare -g VERSION=""
declare -g BUILD_DATE=""

declare -g PART=""
declare -g CHAPTER=""
declare -g DESCRIPTION=""
declare -g SECTIONS=""

declare -g PADDED_PART=""
declare -g PADDED_CHAPTER=""
declare -g PART_DIR=""
declare -g CHAPTER_DIR=""
declare -g CHAPTER_FILE=""

declare -g CONFIG_FILE=""
declare -g COMPONENTS=""
declare -g COLOR_SCHEME=""
declare -g FRONTMATTER=""

export SCRIPT_DIR WORKSPACE_ROOT
export TYPE CATEGORY NAME TITLE AUTHOR EMAIL URL SUBTITLE SUBJECT KEYWORDS
export TARGET_DIR WORKSPACE_FILE
export SOURCE OUTPUT_DIR ENGINE BIBTEX
export CLEAN WATCH QUIET INTERACTIVE FORCE BACKUP CHECK_ONLY VERBOSE
export BASENAME PDF_NAME
export PROJECT_TYPE PROJECT_CATEGORY OVERRIDE_DIR
export VERSION BUILD_DATE
export PART CHAPTER DESCRIPTION SECTIONS
export PADDED_PART PADDED_CHAPTER PART_DIR CHAPTER_DIR CHAPTER_FILE
export CONFIG_FILE COMPONENTS COLOR_SCHEME FRONTMATTER