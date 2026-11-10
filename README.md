# Papyrxis Workspace

One reusable workspace for books, booklets, articles and other LaTeX documents.

Workspace is the shared toolset and document scaffold used by projects in the Papyrxis organization. A project keeps its content and one workspace.yml; Workspace owns the reusable build, export, configuration, logging and release tooling.

It is deliberately project-neutral. A new project does not inherit an author's name, journal style or release policy. Defaults are small and conventional. Project YAML overrides defaults; CLI arguments override YAML.

## What belongs here

- Reusable Python tooling for initialization, configuration, LaTeX builds, PDF validation, Markdown export, tags and changelogs.
- Standard English and Persian build support, including separate engines per language.
- Shared article, book and booklet templates and reusable LaTeX components.
- Export target profiles for platforms such as dev.to, Medium and IEEE. CSL is opt-in per target.
- Common automation: Make targets, gix flow configuration, psx quality policy and pipeline CI tasks.
- Documentation and examples so another author can start without learning the internals.

Actual books and articles stay in their own repositories. Personal CVs should be separate repositories too; their template can still use Workspace.

## Requirements

- Python 3.10+ and pip.
- TeX Live or MiKTeX, with latexmk and the engines selected in workspace.yml.
- Pandoc only when exporting Markdown.
- gix and psx for repository flow and quality checks.
- m-mdy-m/log.c shared library for native structured logs. See docs/getting-started.md.

## Start a project

~~~sh
python -m pip install -e /path/to/workspace
mkdir my-book && cd my-book
px init --type book --language en
~~~

Or use Workspace as a Git submodule:

~~~sh
git submodule add https://github.com/papyrxis/workspace.git workspace
python -m pip install -e workspace
px init --type book --language en
~~~

Build with:

~~~sh
make build
make clean
~~~

For a bilingual project, use px init --type book --language both. It creates separate English and Persian entries with independent engines in workspace.yml.

## Project layout

~~~text
my-book/
├── workspace.yml
├── Makefile
├── main.tex
├── chapters/
├── frontmatter/
├── backmatter/
├── figures/
├── references/
│   └── references.bib
└── build/                 generated output; do not edit
~~~

Articles use sections/ instead of chapters/. A bilingual project may keep en/ and fa/ entry points.

## Configuration

The project-level workspace.yml is the source of truth. Built-in defaults provide a starting point; YAML replaces or extends those values; CLI options have the highest precedence.

~~~yaml
schema_version: 1

project:
  name: my-book
  type: book
  title: "My Book"
  author: "Your Name"
  languages: [en, fa]

build:
  output_dir: build
  entries:
    en:
      source: en/main.tex
      engine: pdflatex
    fa:
      source: fa/main.tex
      engine: xelatex

export:
  output_dir: build/export
  targets: [devto]
  tag_limit: 5
~~~

See docs/configuration.md and schemas/workspace.schema.json.

## Common commands

~~~sh
px init --type article --language both
px build --language en
px build --language fa
px export --target devto
px tags
px changelog
gix version bump minor
px tag v1.2.0 --sign
px push --tags
~~~

Equivalent Make targets are documented in docs/scripts.md.

## CI, quality and Git flow

- CI tasks live in pipeline.toml and run through m-mdy-m/pipeline.
- psx.yml defines repository quality policy; it does not duplicate CI task logic.
- .gix/config defines branch flow. Use gix feature start and gix feature finish.
- The shared logger is m-mdy-m/log.c; Workspace calls its stable C ABI through ctypes. A simple stderr fallback is used during bootstrap if the shared library is not installed.

Read docs/architecture.md, docs/getting-started.md, docs/configuration.md, docs/build-and-export.md, docs/multi-document.md, docs/logging.md and docs/releasing.md.

## License

Workspace tooling is MIT-licensed. Document contents created with Workspace retain the license chosen by each publishing project. Third-party fonts, LaTeX packages, CSL files and templates retain their respective licenses.

## Multi-document publishing (schema v2)

Schema v1 remains supported for existing single-document projects. For a repository containing independent papers, booklets or volumes, use schema v2 with named documents and editions:

~~~sh
cd examples/multi-document
px list
px build
px build bilingual-handbook --edition fa
px verify
px clean arliz-volume-2
~~~

Outputs are isolated under `build/<document-id>/<edition>/`; `build/manifest.json` records every successful artifact and its SHA-256. See [the multi-document guide](docs/multi-document.md) and the runnable [multi-document fixture](examples/multi-document/README.md).

## Release assets and containers

Push a SemVer tag (including prerelease tags such as `v0.3.0-beta.1`) to invoke the shared `m-mdy-m/pipeline` release workflow. It tests the package, builds wheel and sdist distributions, creates a deterministic self-verifying ZIP bundle, and attaches all files plus checksums to the GitHub Release. Prerelease tags are published as GitHub prereleases by Pipeline.

The Docker image is published to GHCR as `ghcr.io/papyrxis/workspace`. Configure repository Actions secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` to additionally publish to Docker Hub as `<username>/papyrxis-workspace`. See [release documentation](docs/releasing.md).

~~~sh
docker pull ghcr.io/papyrxis/workspace:latest
docker run --rm ghcr.io/papyrxis/workspace:latest --help
# Mount a project to build it:
docker run --rm -v "$PWD:/workspace" -w /workspace ghcr.io/papyrxis/workspace:latest build
~~~
