#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/common.sh"

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Update Papyrxis workspace to latest version.

OPTIONS:
    -f, --force          Force update even if uncommitted changes
    -b, --backup         Create backup before update
    -c, --check          Check for updates without applying
    -v, --verbose        Show detailed output
    -h, --help           Show this help

EXAMPLES:
    $0                   # Check and update if available
    $0 -b                # Backup and update
    $0 -c                # Just check for updates

NOTES:
    - Backs up workspace.yml automatically
    - Re-runs sync after update
    - Shows changelog if available

EOF
}

FORCE=false
BACKUP=false
CHECK_ONLY=false
VERBOSE=false

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
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Check if we're in a project with workspace submodule
if [[ ! -d "workspace/.git" ]]; then
    error "Not a workspace submodule. Run this from project root with workspace/ submodule."
fi

log "Checking workspace status..."

# Check for uncommitted changes
cd workspace
if ! $FORCE && ! git diff-index --quiet HEAD -- 2>/dev/null; then
    error "Workspace has uncommitted changes. Use -f to force update."
fi
cd ..

# Backup workspace.yml if requested or if it exists
if $BACKUP || [[ -f "workspace.yml" ]]; then
    if [[ -f "workspace.yml" ]]; then
        BACKUP_FILE="workspace.yml.backup.$(date +%Y%m%d_%H%M%S)"
        log "Backing up configuration to $BACKUP_FILE"
        cp workspace.yml "$BACKUP_FILE"
    fi
fi

# Fetch updates
log "Fetching workspace updates..."
cd workspace
git fetch origin

# Get current and remote versions
CURRENT_COMMIT=$(git rev-parse HEAD)
CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
REMOTE_COMMIT=$(git rev-parse origin/main)
REMOTE_TAG=$(git describe --tags --abbrev=0 origin/main 2>/dev/null || echo "unknown")

info "Current version: $CURRENT_TAG ($CURRENT_COMMIT)"
info "Remote version: $REMOTE_TAG ($REMOTE_COMMIT)"

# Check if update available
if [[ "$CURRENT_COMMIT" == "$REMOTE_COMMIT" ]]; then
    log "✓ Workspace is up to date!"
    cd ..
    exit 0
fi

log "Update available!"

# Show changes
if $VERBOSE; then
    log "Changes since your version:"
    git log --oneline --decorate "$CURRENT_COMMIT..$REMOTE_COMMIT"
fi

# Check if there's a CHANGELOG
if [[ -f "CHANGELOG.md" ]] && $VERBOSE; then
    log "Recent changes:"
    echo "---"
    awk "/^## \[$REMOTE_TAG\]/,/^## \[/" CHANGELOG.md | head -n -1
    echo "---"
fi

if $CHECK_ONLY; then
    log "Check complete. Use without -c to apply update."
    cd ..
    exit 0
fi

# Ask for confirmation unless forced
if ! $FORCE; then
    read -p "Update workspace from $CURRENT_TAG to $REMOTE_TAG? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Update cancelled"
        cd ..
        exit 0
    fi
fi

# Perform update
log "Updating workspace..."
git checkout main
git pull origin main

NEW_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "latest")
log "✓ Updated to version: $NEW_VERSION"

cd ..

# Check for breaking changes or migrations
if [[ -f "workspace/MIGRATION.md" ]]; then
    warn "Migration guide available: workspace/MIGRATION.md"
    warn "Please review for breaking changes!"
fi

# Re-sync components
log "Re-syncing components..."
if [[ -f "workspace.yml" ]]; then
    bash workspace/scripts/sync.sh
    log "✓ Components synced"
else
    warn "No workspace.yml found. Run init.sh if needed."
fi

# Clean rebuild recommended
info ""
info "Update complete!"
info "Recommended next steps:"
info "  1. Review changes: cat workspace/CHANGELOG.md"
info "  2. Check migration guide (if any): cat workspace/MIGRATION.md"
info "  3. Clean rebuild: make clean && make"
info "  4. Test your build"
info ""
if $BACKUP; then
    info "Configuration backup: $BACKUP_FILE"
fi

# Show what changed in components (if verbose)
if $VERBOSE; then
    log "Updated components:"
    git -C workspace diff --name-only "$CURRENT_COMMIT" "$REMOTE_COMMIT" | grep "^common/" || true
fi