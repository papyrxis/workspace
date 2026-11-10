# Multi-document projects

Schema v2 lets one repository describe independent publications without introducing separate build engines. A document has a stable ID, a document profile, metadata, and one or more editions. An edition is commonly a language, but it can also represent another independently built variant.

## Configuration

~~~yaml
schema_version: 2

project:
  name: research-library
  type: collection
  title: Research Library
  author: Papyrxis
  languages: [en, fa]

build:
  output_dir: build
  default_engine: xelatex
  timeout_seconds: 1800

documents:
  paper-01:
    type: article
    title: First Paper
    editions:
      en:
        source: papers/first/en.tex
        engine: pdflatex
  booklet:
    type: booklet
    title: Bilingual Booklet
    editions:
      en:
        source: booklets/guide/en.tex
        engine: pdflatex
      fa:
        source: booklets/guide/fa.tex
        engine: xelatex
  volume-01:
    type: book
    title: First Volume
    editions:
      en:
        source: books/volume-01.tex
        engine: pdflatex
        output_name: volume-01

export:
  output_dir: build/export
  targets: [devto]
  tag_limit: 5
~~~

The root project type may be `collection` in schema v2. Each document must use one of the supported concrete profiles: `book`, `booklet`, `article`, or `cv`. `project.languages` declares the editions used by the collection; each edition ID must be a safe identifier.

## CLI

~~~sh
px list
px list --json
px build
px build paper-01
px build booklet --edition fa
px build volume-01 --edition en --dry-run
px verify
px clean volume-01
px clean
~~~

The existing `px build --language en` option remains as a v1-compatible alias for selecting one edition. Use `--edition` for schema v2.

- `px list` lists each document and edition, source, and latest manifest status.
- `px build` builds all declared documents and editions.
- `px build <document-id>` builds one document.
- `px build <document-id> --edition <edition-id>` builds one edition.
- `px clean <document-id>` removes only that document's generated output.
- `px verify` validates every successful PDF recorded in the build manifest.

## Output and manifest

Each schema-v2 artifact is isolated:

~~~text
build/
├── paper-01/
│   └── en/first.pdf
├── booklet/
│   ├── en/en.pdf
│   └── fa/fa.pdf
├── volume-01/
│   └── en/volume-01.pdf
└── manifest.json
~~~

The manifest is written atomically and has a stable ordering. Successful result records contain document ID/type/title, edition, source, selected engine, output path, byte size, and SHA-256. Failed editions contain a failure status and diagnostic message. The summary records planned/completed/failed counts and whether the command was a dry run.

`px verify` rejects missing or malformed PDFs and any artifact whose size or SHA-256 differs from the manifest. The manifest is a build receipt, not a signed provenance statement; use protected CI and release attestations when publisher authenticity is required.

## Failure policy

By default, the first build failure stops subsequent work and a manifest is still written for the attempted results. Use `--keep-going` to attempt independent editions after a failure. Any failed edition makes the command return a non-zero exit status. A partial manifest must never be interpreted as a successful full build.

## v1 compatibility and migration

Schema v1 remains supported. Its `build.entries` map is normalized internally to one document with language editions, and its existing `build/<language>/` output path is preserved. No source files need to move.

To migrate:
1. Keep `project` metadata and `build.output_dir`.
2. Change `schema_version` to `2`.
3. Add a `documents` mapping with one or more named documents.
4. Move each v1 `build.entries.<language>` source/engine pair into the appropriate document's `editions.<language>`.
5. Remove the old `build.entries` mapping after verifying all sources are represented.
6. Run `px list --json`, `px build --dry-run`, then `px build` and `px verify`.

A collection's language is an edition dimension, not a document identity. Do not encode a separate document ID for every language copy unless the content is actually an independent publication.
