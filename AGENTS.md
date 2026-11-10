# AGENTS.md — Papyrxis Workspace

## Mission

Workspace is the shared, project-neutral publishing platform for Papyrxis repositories. It owns reusable authoring/build/release tooling; consuming repositories own their editorial content and project-specific metadata.

## Read first

- `README.md`
- `docs/architecture.md`
- `docs/configuration.md`
- `docs/build-and-export.md`
- `docs/releasing.md`
- `schemas/workspace.schema.json`
- `pipeline.toml`

## Architecture rules

1. Extend the existing `px` package. Do not create parallel book, article, booklet, collection, release, or build engines.
2. Keep v1 configuration compatible. New multi-document configuration is an additive schema version with an explicit migration path.
3. Separate document identity from edition identity: a document has one or more language/edition variants.
4. Build planning must be deterministic. Resolve and validate every source/output path before executing commands.
5. Prevent path traversal and symlink escapes for source, output, manifest, and package paths.
6. Never silently overwrite outputs when two documents resolve to the same destination. Detect collisions during planning, before running LaTeX.
7. Build failures must be explicit and attributable to a document and edition. Support collecting independent failures when configured; never report a partial run as successful.
8. Write machine-readable manifests atomically. Include stable document/edition IDs, source, engine, output, status, size, SHA-256, and tool/version metadata where available.
9. Keep subprocess execution centralized in `px.process`; pass argument arrays, never shell-interpolated YAML values.
10. Use `m-mdy-m/log.c` through the documented stable ABI. Keep component names in log events; fallback output is only for bootstrap/development and must be visible in diagnostics.
11. Keep `m-mdy-m/pipeline` as the CI/task/release engine. GitHub Actions should be thin provider adapters for credentials, runners, artifact transfer, and registry publishing.
12. Keep `gix` responsible for Git flow/version calculation and `psx` responsible for repository quality policy. Do not reimplement them.
13. Keep GitHub Release assets, Python distributions, GitHub Packages, GHCR, and Docker Hub as explicit, independently verifiable distribution targets.
14. Publishing must be opt-in and credential-gated. CI pull-request jobs must never publish. Never log secrets.
15. Docker images must be reproducible, non-root by default where practical, versioned, labeled with OCI metadata, and include a health/smoke test.
16. Examples must be runnable fixtures, not aspirational fragments. E2E tests must exercise public CLI entry points and verify generated files/manifests/checksums.
17. Preserve existing shell integration until consuming repositories have migrated and their CI proves compatibility.

## Quality gates

- Unit tests for configuration, planning, collision detection, path safety, manifest determinism, packaging, and CLI exit behavior.
- E2E tests for single-document v1, multi-document v2, bilingual editions, mixed engines, partial failures, and package installation.
- Run `pipeline validate`, `pipeline list`, and `pipeline run check` locally/CI.
- Build and inspect wheel/sdist; install the wheel in a clean environment and run `px --help` and a smoke project.
- Build Docker image, run container smoke tests, and verify OCI labels. Registry pushes only run on trusted release events with configured secrets.
- Release assets include checksums and a machine-readable package manifest; verify every asset before publishing.

## Change discipline

- Make small, reviewable Conventional Commits.
- Update schema, docs, examples, and tests together with behavior changes.
- Do not claim a CI, release, registry push, or E2E test passed unless the corresponding run/result was observed.
- Do not close Issue #10 until every acceptance criterion is implemented and validated, or explicitly split remaining migration work into linked issues.
