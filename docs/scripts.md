# Script Reference

Complete reference for all Papyrxis scripts.

## Overview

Papyrxis includes several bash scripts for project management, building, and automation. All scripts are in the scripts/ directory.

Scripts handle:
- Project initialization
- Component synchronization
- Document building
- Content generation
- Workspace updates

## Core Scripts

### init.sh

Initialize a new Papyrxis project.

**Location:** scripts/init.sh

**Purpose:**
Creates new project structure with configuration, templates, and build system.

**Usage:**
```bash
bash workspace/scripts/init.sh [OPTIONS]
```

**Options:**

```
-t, --type TYPE         Project type: book|article (required)
-c, --category CAT      Category: technical|academic (default: technical)
-n, --name NAME         Project name (default: current directory name)
--title TITLE          Document title
--author AUTHOR        Author name (default: from git config)
--email EMAIL          Author email (default: from git config)
--url URL              Project URL (auto-detected from git remote)
-d, --dir DIR          Target directory (default: current directory)
--interactive          Interactive mode (prompt for all values)
-h, --help             Show this help
```

**Examples:**

Quick start:
```bash
bash workspace/scripts/init.sh -t book --title "My Book"
```

Full specification:
```bash
bash workspace/scripts/init.sh \
  -t book \
  -c technical \
  --title "My Technical Book" \
  --author "Your Name" \
  --email "you@example.com" \
  --url "https://github.com/user/repo"
```

Interactive mode:
```bash
bash workspace/scripts/init.sh -t book --interactive
```

**What it does:**

1. Detects git info (author, email, remote URL)
2. Creates workspace.yml configuration
3. Sets up directory structure
4. Copies and populates templates
5. Creates Makefile
6. Creates .gitignore
7. Creates README.md

**Output files:**

- workspace.yml
- main.tex
- Makefile
- README.md
- .gitignore
- Directory structure (parts/, frontmatter/, etc.)

**Exit codes:**

- 0: Success
- 1: Error (missing required option, invalid type, etc.)

### sync.sh

Synchronize workspace components based on workspace.yml.

**Location:** scripts/sync.sh

**Purpose:**
Reads workspace.yml and generates .pxis/ directory with required components.

**Usage:**
```bash
bash workspace/scripts/sync.sh
```

Or through Makefile:
```bash
make sync
```

**Options:**

None. Configuration comes from workspace.yml.

**Examples:**

After editing workspace.yml:
```bash
make sync
```

Manual sync:
```bash
bash workspace/scripts/sync.sh
```

**What it does:**

1. Reads workspace.yml configuration
2. Validates settings
3. Creates .pxis/ directory structure
4. Copies required components to .pxis/components/
5. Checks for custom overrides in configs/
6. Applies color scheme
7. Generates frontmatter (cover, copyright, title)
8. Creates .pxis/preset.tex with all includes
9. Adds metadata and version info

**Output:**

- .pxis/preset.tex (main preset file)
- .pxis/components/ (synced components)
- .pxis/generated/ (generated content)
- frontmatter/ (generated front matter)

**Exit codes:**

- 0: Success
- 1: Error (no workspace.yml, invalid config, missing component)

**Validation:**

Checks for:
- Required configuration fields
- Valid component names
- Component dependencies
- Allowed overrides
- File existence

### build.sh

Build LaTeX document with proper dependency handling.

**Location:** scripts/build.sh

**Purpose:**
Orchestrates LaTeX compilation with bibliography processing and multiple passes.

**Usage:**
```bash
bash workspace/scripts/build.sh [OPTIONS] [SOURCE.tex]
```

Or through Makefile:
```bash
make build
make        # same as 'make build'
```

**Options:**

```
-o, --output DIR     Output directory (default: from config or 'build')
-e, --engine ENGINE  LaTeX engine: pdflatex|xelatex|lualatex
-b, --bibtex TOOL    Bibliography tool: biber|bibtex
-c, --clean          Clean build directory before building
-w, --watch          Watch mode: rebuild on file changes
-q, --quiet          Suppress non-error output
-h, --help           Show this help
```

**Examples:**

Standard build:
```bash
make
```

Clean build:
```bash
make clean
make
```

Watch mode:
```bash
make watch
```

Custom engine:
```bash
bash workspace/scripts/build.sh -e xelatex main.tex
```

**What it does:**

1. Reads workspace.yml for build settings
2. Validates LaTeX engine and bibtex tool exist
3. Gets version from git
4. Runs first LaTeX pass
5. Runs bibliography processor (if needed)
6. Runs second LaTeX pass (for citations)
7. Runs third LaTeX pass (for references)
8. Reports success or errors

**Build process:**

Pass 1: Initial compilation
- Generate auxiliary files
- Process document structure

Pass 2 (if bibliography): Process bibliography
- Run biber/bibtex
- Generate bibliography

Pass 3: Update citations
- Incorporate bibliography references
- Update citation numbers

Pass 4: Final pass
- Resolve all references
- Generate final PDF

**Output:**

- build/main.pdf (final document)
- build/*.aux, *.log, etc. (auxiliary files)

**Exit codes:**

- 0: Success, PDF created
- 1: Error, PDF not created

**Watch mode:**

Monitors file changes and rebuilds automatically. Uses:
- inotifywait (Linux)
- fswatch (macOS)
- Polling fallback

Stop with Ctrl+C.

### update.sh

Update Papyrxis workspace to latest version.

**Location:** scripts/update.sh

**Purpose:**
Updates workspace submodule while preserving your configuration.

**Usage:**
```bash
bash workspace/scripts/update.sh [OPTIONS]
```

**Options:**

```
-f, --force          Force update even if uncommitted changes
-b, --backup         Create backup before update
-c, --check          Check for updates without applying
-v, --verbose        Show detailed output
-h, --help           Show this help
```

**Examples:**

Check for updates:
```bash
bash workspace/scripts/update.sh -c
```

Update with backup:
```bash
bash workspace/scripts/update.sh -b
```

**What it does:**

1. Checks for uncommitted workspace changes
2. Backs up workspace.yml if requested
3. Fetches upstream changes
4. Shows version difference
5. Displays changelog
6. Prompts for confirmation
7. Updates workspace submodule
8. Re-runs sync to apply changes
9. Reports migration requirements if any

**Output:**

- Updated workspace/ submodule
- .pxis/ regenerated
- Backup file (if -b used)

**Exit codes:**

- 0: Success or already up to date
- 1: Error or update cancelled

## Generator Scripts

Scripts for generating content.

### generator/part.sh

Generate new book part.

**Location:** scripts/generator/part.sh

**Usage:**
```bash
bash workspace/scripts/generator/part.sh [OPTIONS]
```

**Options:**

```
-n, --number NUM      Part number (1, 2, 3, ...)
-t, --title TITLE     Part title
-d, --desc TEXT       Part description (optional)
-h, --help           Show this help
```

**Example:**

```bash
bash workspace/scripts/generator/part.sh \
  -n 2 \
  -t "Advanced Topics" \
  -d "Deep dive into advanced concepts"
```

**What it does:**

1. Creates parts/partNN/ directory
2. Generates partNN.tex with structure
3. Includes part intro environment
4. Provides instructions for adding to main.tex

**Output:**

- parts/part02/part02.tex

### generator/chapter.sh

Generate new book chapter.

**Location:** scripts/generator/chapter.sh

**Usage:**
```bash
bash workspace/scripts/generator/chapter.sh [OPTIONS]
```

**Options:**

```
-p, --part NUM        Part number (1, 2, 3, ...)
-c, --chapter NUM     Chapter number (1, 2, 3, ...)
-t, --title TITLE     Chapter title
-d, --desc TEXT       Chapter description (optional)
-s, --sections LIST   Comma-separated section names
-h, --help           Show this help
```

**Example:**

```bash
bash workspace/scripts/generator/chapter.sh \
  -p 1 \
  -c 3 \
  -t "Data Structures" \
  -s "Introduction,Analysis,Implementation"
```

**What it does:**

1. Creates chapter directory and subdirectories
2. Generates chapter.tex with structure
3. Creates initial sections if specified
4. Provides instructions for including in part file

**Output:**

- parts/part01/chapter03/chapter03.tex
- parts/part01/chapter03/figures/

### generator/cover.sh

Generate book cover page.

**Location:** scripts/generator/cover.sh

**Usage:**
```bash
bash workspace/scripts/generator/cover.sh [CONFIG_FILE]
```

**Example:**

```bash
bash workspace/scripts/generator/cover.sh workspace.yml
```

**What it does:**

1. Reads cover configuration from workspace.yml
2. Determines cover style (modern, classic, minimal)
3. Generates LaTeX cover code
4. Creates frontmatter/cover.tex

**Styles:**

- modern: Geometric patterns, contemporary design
- classic: Traditional academic style
- minimal: Clean and simple

**Output:**

- frontmatter/cover.tex

### generator/copyright.sh

Generate copyright page.

**Location:** scripts/generator/copyright.sh

**Usage:**
```bash
bash workspace/scripts/generator/copyright.sh [CONFIG_FILE]
```

**Example:**

```bash
bash workspace/scripts/generator/copyright.sh workspace.yml
```

**What it does:**

1. Reads copyright settings from workspace.yml
2. Determines license type
3. Generates appropriate copyright text
4. Creates frontmatter/copyright.tex

**License types supported:**

- Creative Commons (cc-by-sa, cc-by, cc-by-nc, cc-by-nc-sa)
- MIT
- Apache 2.0
- Custom
- None

**Output:**

- frontmatter/copyright.tex

## Utility Scripts

### common.sh

Shared functions for all scripts.

**Location:** scripts/common.sh

**Purpose:**
Provides common functionality used by all scripts.

**Not run directly.** Sourced by other scripts:

```bash
source "$SCRIPT_DIR/common.sh"
```

**Functions provided:**

Logging:
- log(): Info message
- warn(): Warning message
- error(): Error and exit
- info(): Information message

Utilities:
- command_exists(): Check if command available
- ensure_dir(): Create directory if not exists
- pad_number(): Zero-pad numbers

Configuration:
- parse_yaml(): Parse YAML files
- load_config(): Load workspace.yml
- get_config(): Get config value with fallback

Version:
- get_version(): Get version from git or config
- get_build_date(): Get current date/time

LaTeX:
- check_latex(): Verify LaTeX engine exists
- check_bibtex(): Verify bibliography tool exists

Copyright:
- generate_copyright_text(): Generate license text

**Environment variables exported:**

All functions are exported for use in other scripts.

## Using Scripts

### Through Makefile

Recommended approach:

```bash
make          # Build
make sync     # Sync components
make clean    # Clean build directory
make watch    # Watch mode
```

Makefile calls scripts with appropriate options.

### Directly

For advanced usage or custom options:

```bash
bash workspace/scripts/build.sh -e xelatex -q main.tex
bash workspace/scripts/sync.sh
bash workspace/scripts/init.sh --interactive
```

### From Your Scripts

Source common.sh to use utilities:

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"

source "$WORKSPACE_ROOT/scripts/common.sh"

# Now use functions
log "Starting custom process"
ensure_dir "output"
VERSION=$(get_version)
```

## Script Requirements

All scripts require:

- Bash 4.0 or later
- Standard Unix tools (sed, awk, grep)
- Git (for version management)

Build scripts additionally require:
- LaTeX distribution (TeX Live or MiKTeX)
- biber or bibtex

Optional:
- Python 3 with PyYAML (for advanced config parsing)
- inotifywait or fswatch (for watch mode)

## Error Handling

Scripts use standard error handling:

- Exit code 0: Success
- Exit code 1: Error

Error messages to stderr.

Use set -euo pipefail for safe execution.

## Script Debugging

To debug scripts:

Enable verbose output:
```bash
bash -x workspace/scripts/build.sh
```

Check specific script:
```bash
bash -n workspace/scripts/sync.sh  # Syntax check
```

Trace execution:
```bash
set -x
bash workspace/scripts/build.sh
set +x
```

## Common Issues

**Permission denied**

Make scripts executable:
```bash
chmod +x workspace/scripts/*.sh
```

**Command not found**

Script not in PATH. Use full path:
```bash
bash workspace/scripts/init.sh
```

Or run from project root:
```bash
bash ./workspace/scripts/init.sh
```

**YAML parsing errors**

Ensure Python 3 with PyYAML installed:
```bash
pip3 install pyyaml
```

Or use basic YAML parsing (automatic fallback).

**Git not found**

Install git or set manual version:
```yaml
version:
  source: manual
  fallback: "1.0.0"
```

## Script Development

When creating new scripts:

1. Start with template:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/common.sh"

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]
...
EOF
}

# Script logic
```

2. Source common.sh for utilities
3. Provide usage function
4. Parse arguments properly
5. Use logging functions
6. Check prerequisites
7. Handle errors gracefully
8. Exit with appropriate code

## Related Documentation

See also:
- getting-started.md - Basic usage
- configuration.md - workspace.yml options
- customization.md - Advanced usage
- templates.md - Template system