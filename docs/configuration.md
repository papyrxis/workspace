# Configuration

Every project has one workspace.yml. Workspace supplies small defaults; project YAML takes precedence. Explicit command-line options take precedence over both.

## Example

~~~yaml
schema_version: 1

project:
  name: nature-of-data
  type: book
  title: "The Nature of Data"
  author: "Your Name"
  languages: [en, fa]
  tags: [data, systems]
  keywords: [information theory, representation]

build:
  output_dir: build
  default_engine: xelatex
  timeout_seconds: 1800
  entries:
    en:
      source: en/main.tex
      engine: pdflatex
    fa:
      source: fa/main.tex
      engine: xelatex

export:
  output_dir: build/export
  targets: [devto, medium]
  tag_limit: 5

targets:
  devto:
    front_matter: true
    format: gfm
    csl: null
    max_tags: 5
~~~

## Project

- name is the stable project slug.
- type is book, booklet, article or cv.
- title and author are document metadata.
- languages lists the editions to build.
- for an `article`, optional `style` selects `personal`, `academic`, `ieee` or `technical`; `px init --type article` defaults to `personal`.
- tags and keywords supply platform tag generation.

## Build

output_dir is the generated artifact directory and must stay inside the project. default_engine is one of pdflatex, xelatex or lualatex. Each entry maps one language to a source path and an optional engine.

Short form:

~~~yaml
entries:
  en: main.tex
~~~

Explicit form:

~~~yaml
entries:
  en:
    source: en/main.tex
    engine: pdflatex
  fa:
    source: fa/main.tex
    engine: xelatex
~~~

Each edition is built independently under `build/<language>/`. `px init --type book` creates chapter/part, front-matter and appendix scaffolding; `--type booklet` creates a compact A5 book profile.

## Export and targets

export.targets chooses the default target profiles. Built-ins include devto, medium, ieee and journal. Project values under targets.<name> override a profile.

CSL is not global and is absent by default. Set it only when a target actually requires a citation style. The built-in IEEE profile ships with the Workspace package, and a project can replace or disable it with a YAML override. dev.to adds front matter and tags; Medium does not. IEEE can use common/csl/ieee.csl. A profile can also list project-owned Pandoc Lua filters.

## Validation

YAML is loaded with yaml.safe_load; it is never evaluated as shell code. Project source and output paths must be relative and cannot escape the project directory. Unknown engines, malformed mappings and unsupported document types fail with a clear error.

The canonical JSON Schema is schemas/workspace.schema.json.

## Schema versions

Workspace accepts schema v1 and v2. Keep v1 for a single document with language editions. Use v2 when a repository contains multiple independent publications. The v2 top-level `documents` mapping is required, and each document owns one or more `editions`; see [Multi-document projects](multi-document.md) for the full schema and migration path. The machine-readable schema is `schemas/workspace.schema.json`.
