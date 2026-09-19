# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Released]

## [Unreleased]

### Added
- `px/` — the Python engine previously living as `scripts/common/` inside the
  `papers` repo, promoted into `workspace` so every consumer shares one
  implementation instead of N copies: `BaseModule` (banner/interactive
  menu/help/dispatch), `colors`, `conf` (.conf parser + index/slug
  resolver), `interactive` (prompt/confirm/choose), `process` (subprocess
  wrappers), `latex` (artifact cleanup + git-describe versioning), `ui`.
- `px/__main__.py` — `python3 -m px clean [path]` and
  `python3 -m px version [path]`, so Makefiles can call the one canonical
  implementation instead of re-deriving the artifact glob list or the
  version string locally.
- `px/watch.py` — the polling watcher now tries `inotifywait` / `fswatch`
  first (mirroring `build.sh`'s existing chain) and only falls back to
  polling if neither is on `PATH`; a real filesystem event is still
  confirmed against the same mtime+size fingerprint before triggering a
  rebuild, so a stray `.aux`/swap-file write won't cause one.

### Changed
- `Makefile`'s `clean` target now calls `python3 -m px clean .` first,
  falling back to the previous hand-rolled `find` pipeline only if
  Python 3 isn't available — same "prefer Python, degrade to bash"
  pattern `parser.sh` already uses for YAML.
- Template placeholder syntax unified on `@TOKEN@` (was `{{TOKEN}}`) in
  `template/books/main.tex`, `template/article/main.tex`,
  `template/books/frontmatter/{preface,acknowledgments}.tex`,
  `src/setup/workspace.sh`, and `src/sync.sh`'s `gen_title`/
  `gen_frontmatter_item` — matching the convention `papers/main.tex` and
  `arliz/main.tex` already use for their own per-item templates.
- `src/utils/logger.sh` now prints the same glyphs as `px/colors.py`
  (`▶`/`✓`/`⚠`/`ℹ`/`✗`, no per-line timestamp) on the same ANSI palette
  — `make sync`/`make build` and `python -m px ...` now read as one tool.

### Known, not touched this round
- `template/books/frontmatter/title.tex` is not reachable from `sync.sh`
  (`gen_title()` only ever reads `common/frontmatter/title.tex`) and its
  content isn't generic — left in place, unreferenced, pending a decision.
- `src/generator/frontmatter.sh` has no caller (no Makefile target, not
  invoked by `sync.sh`) — still uses `{{TOKEN}}` internally; left as-is
  since it's dead code either way.

## [0.1.0] - 2026-01-01

### Added
- Initial version of the workspace build system and document generator.
- Python-based YAML parser for robust configuration loading (`parser.py` + `parser.sh`).
- Bash fallback YAML parser for environments without Python.
- Scripts for workspace initialization, syncing, building, and generating parts, chapters, and cover pages.
- `Makefile` build system with targets: `all`, `sync`, `build`, `clean`, `watch`, `version`, `part`, `chapter`, `cover`, `test`, `help`.
- Example workspace templates and configuration (`workspace.yml`).
- Logging and improved CLI handling for init and build commands.
- LaTeX templates and frontmatter support for generating documents.
- Initial examples and generator scripts for parts, chapters, and cover pages.
- Support for automated cleaning of LaTeX build artifacts.
- Versioning and build date info available via `make version`.


[Released]: https://github.com/papyrxis/workspace/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/papyrxis/workspace/releases/tag/v0.1.0
