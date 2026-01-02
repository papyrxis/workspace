# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Released]

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
