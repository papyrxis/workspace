# Command reference

The Makefile is a thin forwarding layer. Shared behavior lives in the px Python package, not in duplicate shell scripts.

## Project lifecycle

| Command | Purpose |
| --- | --- |
| px init --type book --language en | Create a standard book project |
| px init --type book --language both | Create independent English and Persian entry points |
| px build | Build all configured language editions |
| px build --language fa | Build only the Persian edition |
| px watch | Rebuild when configured entry files change |
| px clean | Remove only the configured generated build directory |
| px doctor | Check LaTeX tools, Pandoc, gix, psx and the native logger |

## Export and metadata

| Command | Purpose |
| --- | --- |
| px export --target devto | Export the configured sources for dev.to |
| px export --target medium | Export Markdown without front matter |
| px export --target ieee | Export using the IEEE citation profile |
| px tags | Generate normalized tags from YAML metadata |
| px changelog | Generate release notes from Conventional Commit subjects |

## Git flow and publishing

| Command | Purpose |
| --- | --- |
| gix flow init | Initialize the configured branch flow |
| gix feature start <name> | Start a feature branch from its configured parent |
| gix feature finish <name> | Merge and clean up the feature branch |
| gix version bump patch | Calculate and create a semantic version tag |
| px tag v1.2.0 --sign | Create an explicit signed tag |
| px push | Push the current branch |
| px push --tags | Push the current branch and all local tags |

## Make shortcuts

~~~sh
make init TYPE=article
make build
make build-en
make build-fa
make export TARGET=devto
make tags
make changelog
make bump LEVEL=minor
make tag VERSION=v1.2.0
make push TAGS=1
make clean
make doctor
make test
~~~

The build command never commits, tags or pushes. Release actions are explicit so an ordinary document build cannot publish an unfinished document by accident.

Legacy sync, part and chapter helpers are retained temporarily for old projects. New behavior must be implemented in px modules and the old shell entry points should not gain duplicated features.


## Diagnostics and shell integration

~~~sh
px doctor
px log --level info --component build "PDF generation started"
px verify-pdf build/en/main.pdf
~~~

`px log` is the structured logging entry point used by legacy Bash scripts; records are routed through `m-mdy-m/log.c`. `px verify-pdf` validates both the PDF signature and its end marker, so a stale or truncated file is not accepted as a successful build.
