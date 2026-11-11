# Architecture

Workspace is a publishing toolchain, not a document monorepo. Each book, booklet or article repository owns its content; Workspace owns shared behavior and reusable templates.

## Ownership boundaries

| Module | Responsibility |
| --- | --- |
| px/config.py | Safe YAML loading, schema validation, defaults and precedence |
| px/build.py | Language entry selection, LaTeX engine invocation and PDF validation |
| px/export.py | Pandoc invocation, optional bibliography processing and Markdown output |
| px/targets.py | Small target profiles; no duplicated shell target scripts |
| px/tags.py | Stable platform-safe tags |
| px/changelog.py | Conventional Commit categorization |
| px/logger.py | m-mdy-m/log.c C ABI adapter |
| px/process.py | One subprocess boundary; commands are argument arrays |
| pipeline.toml | Provider-neutral CI task graph |
| psx.yml | Repository structure and quality policy |
| .gix/config | Branch and release flow |

## Configuration precedence

1. Built-in Workspace defaults.
2. Project workspace.yml.
3. Explicit CLI options.

Project settings replace default scalar values and lists. Nested mappings merge recursively. This lets a project customize one export target or one language engine without forking Workspace.

## Build flow

px build reads build.entries and compiles each entry using its selected engine. Outputs are isolated under build/<language>/. A build succeeds only if the LaTeX command succeeds and the expected PDF has a valid header and EOF marker.

A project Makefile can orchestrate a specialized build. The Pipeline LaTeX preset prefers make build when present, allowing English and Persian editions to use different engines.

## Export flow

px export delegates LaTeX-to-Markdown conversion to Pandoc. Targets own only meaningful differences: format, front matter, filters and optional CSL. There is no default global CSL. A target without CSL does not invoke citeproc.

## Logging

px.logger binds the stable non-variadic mmlog_event_t interface from m-mdy-m/log.c. It checks ABI major version 1 and calls the native logger when installed. During bootstrap it falls back to plain stderr output; px doctor reports whether the native library is active.

## Extension rule

A helper shared by more than one command belongs in px/ exactly once. Make targets and provider workflows are entry points, not alternate implementations of YAML parsing, LaTeX compilation, export, tags or release notes.

## Multi-document projects (schema v2)

Schema v1 remains the default and is normalized into one logical document. Schema v2 adds a top-level `documents` mapping. Each document owns a profile/type, title and one or more `editions`; an edition selects its source, LaTeX engine and optional output filename. Language codes are edition identifiers rather than document identities.

The build planner validates the entire selected plan before invoking LaTeX. Each v2 artifact is written to `<build.output_dir>/<document-id>/<edition-id>/<output-name>.pdf`, so separate documents and editions cannot overwrite one another. Source and output paths are resolved under the project root, including symlink resolution. The machine-readable `manifest.json` is atomically replaced after a run and records each result, byte size and SHA-256. `px verify` checks PDF structure and verifies size/digest against that manifest.

A v1 project is represented internally as one document with its configured language entries as editions. Its existing `build/<language>/` output layout is retained. This permits the CLI and manifest machinery to be shared without forcing a v1 migration.

See [multi-document configuration and CLI](multi-document.md).
