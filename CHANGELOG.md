# Changelog

All notable changes to Papyrxis Workspace are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Schema-v2 collection projects with multiple named documents and independently configured language editions.
- Document-aware CLI commands: `px list`, `px build <document-id>`, `px clean <document-id>`, and `px verify`.
- Deterministic build manifests containing per-edition status, artifact size, and SHA-256 hashes.
- Safe multi-document build planning, isolated output paths, and protection against path traversal and symlink escapes.
- Shared LaTeX components, presets, and packages available to source checkouts and installed wheels.
- Reproducible release bundles containing the wheel, source distribution, package manifest, and checksums.
- Pipeline-based release automation with asset signing and provenance attestations.
- Multi-platform Docker image publishing to GHCR, with optional Docker Hub publishing.
- An OCI-distributed, verifiable release bundle in GitHub Container Registry.
- End-to-end tests for installed-package resources and real containerized LaTeX builds.

### Changed
- Promoted the publishing engine into the reusable `px` package instead of keeping consumer-specific copies.
- Kept schema-v1 projects and their historical build-output layout backward-compatible.
- Centralized release preparation and publication on `m-mdy-m/pipeline@main`.
- Standardized component logging through the `m-mdy-m/log.c` adapter.

### Fixed
- Prevented document builds and cleanup from escaping their configured project/output boundaries.
- Preserved unrelated document manifest entries when only one document or edition is rebuilt.
- Made packaged shared TeX resources discoverable after installing the wheel.

### Documentation
- Added architecture guidance, multi-document configuration examples, logging integration, and release instructions.
- Added examples covering a single article, multiple papers, bilingual booklets, and multi-volume books.

## [0.1.0] - 2026-01-01

### Added
- Initial version of the workspace build system and document generator.
- Python-based YAML configuration parser with a Bash fallback.
- Workspace initialization, synchronization, build, and document-generation scripts.
- Makefile targets for building, cleaning, watching, versioning, and generating document sections.
- LaTeX templates, frontmatter support, logging, and initial project examples.

[Unreleased]: https://github.com/papyrxis/workspace/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/papyrxis/workspace/releases/tag/v0.1.0
