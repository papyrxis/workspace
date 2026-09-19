#!/usr/bin/env bash

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Same ANSI palette AND same glyphs as px/colors.py (the Python side of
# this engine) — ▶ log, ✓ success, ⚠ warn, ℹ info, ✗ error/fail — so
# `make sync`/`make build` and `python -m px ...` read as one tool
# instead of two differently-styled ones. No per-line timestamp, matching
# the Python side; pipe through `ts` yourself if you need timestamped logs.

log() {
    echo -e "${BLUE}▶${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}⚠${NC} $*" >&2
}

error() {
    echo -e "${RED}✗${NC} $*" >&2
    exit 1
}

info() {
    echo -e "${CYAN}ℹ${NC} $*" >&2
}

debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${CYAN}·${NC} $*" >&2
    fi
}

success() {
    echo -e "${GREEN}✓${NC} $*" >&2
}

fail() {
    echo -e "${RED}✗${NC} $*" >&2
}

export -f log warn error info debug success fail