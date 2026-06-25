# Papyrxis Workspace

A LaTeX workspace for writing books and papers the way you want to write them.
Not a framework, not magic — just organized components and a build system that stays out of the way.

## What it does

- Keeps LaTeX components modular so you can swap or extend anything
- Builds PDFs with a single `make` command
- Lets you override only what you need, without touching the rest
- Handles versioning from git tags
- Ships GitHub Actions workflows for publishing releases

## Requirements

- TeX Live (full) or MiKTeX
- Bash 4+, Make, Git
- Python 3 + PyYAML (`pip install pyyaml`)

## Starting a project

```bash
mkdir my-book && cd my-book
git init
git submodule add https://github.com/papyrxis/workspace.git
bash workspace/src/init.sh
```

That's it. The script asks a few questions and sets up everything.

## Building

```bash
make          # build
make watch    # auto-rebuild when you save
make clean    # remove build artifacts
make sync     # re-sync .pxis/ after editing workspace.yml
```

## Directory layout

```
my-book/
├── workspace/          ← submodule (this repo)
├── workspace.yml       ← your configuration
├── main.tex            ← document entry point
├── Makefile
├── parts/              ← book chapters (books only)
├── frontmatter/        ← title, preface, copyright
├── backmatter/
├── sections/           ← article sections (articles only)
├── figures/
├── references/
│   └── main.bib
├── configs/            ← your component overrides
└── .pxis/              ← auto-generated, don't edit
```

## Configuration

Everything lives in `workspace.yml`. Key settings:

```yaml
project:
  type: book            # book | article
  title: "My Title"
  author: "Your Name"
  url: "https://github.com/you/repo"

build:
  source: main.tex      # which .tex file to compile
  engine: pdflatex
```

Run `make sync` after any change to `workspace.yml`.

See `examples/workspace.config.yml` for all options.

## Overriding components

Put your `.tex` files in `configs/`. Any file whose name matches a component
replaces that component. `mode: extend` appends your file after the default instead.

```yaml
overrides:
  dir: "configs"
  mode: replace         # or: extend
```

Example: to customize colors, create `configs/colors.tex`. Done.

## Adding structure (books)

```bash
make part    ARGS='-n 1 -t "Part One"'
make chapter ARGS='-p 1 -c 1 -t "Getting Started"'
```

## Bibliography

Default style is `authoryear` with footnote citations.
Use `\autocite{key}` for footnotes, `\textcite{key}` for "Author (year)" in text.
`\printbibliography` goes at the end.

For numeric citations, override `bibliography.tex` in your `configs/`.

## Releasing

After `make sync` (with `.pxis/` committed), tag and push:

```bash
git tag v1.0.0
git push --tags
```

The included workflow builds your PDF and publishes a GitHub Release automatically.
A rolling pre-release draft is also built on every push to `main`.

See `.github/workflows/` in your project after `init`.

## License

MIT — see [LICENSE](LICENSE)

Created by Mahdi ([@m-mdy-m](https://github.com/m-mdy-m))
