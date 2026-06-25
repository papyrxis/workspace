# Configuration Reference

All settings live in `workspace.yml`. Run `make sync` after any change.

## project

```yaml
project:
  type: book          # book | article
  title: "My Title"
  author: "Your Name"
  email: "you@example.com"
  url: "https://github.com/you/repo"
```

`type` affects which components are included by default and how frontmatter is generated.

## build

```yaml
build:
  source: main.tex    # which .tex file to compile (default: main.tex)
  engine: pdflatex    # pdflatex | xelatex | lualatex
  bibtex: biber       # biber | bibtex
  output_dir: build
```

`source` is the key setting for multi-file projects. For a book with a specific
naming scheme like `2026_MyBook_Volume_1.tex`, set it here and `make build`
will pick it up automatically.

## components

```yaml
components:
  - fonts
  - math
  - graphics
  - tables
  - hyperref
  - colors
  - layout
  - titles
  - pagestyles
  - env
  - index
  - bibliography
  - code
  - boxes
  - commands/base
```

Default sets are applied when this section is absent:
- **book**: full list above
- **article**: `fonts math graphics tables hyperref colors layout bibliography code commands/base`

## overrides

```yaml
overrides:
  dir: "configs"      # directory containing your .tex overrides
  mode: replace       # replace | extend
```

**replace** (default): your file in `configs/component.tex` replaces the default.

**extend**: the default component loads first, then your file is appended.
Useful for adding commands without duplicating the default setup.

Any `.tex` file in `configs/` whose name matches a component name is automatically
picked up. No whitelist needed.

## colors

```yaml
colors:
  scheme: technical   # technical | academic
```

Override completely by placing `configs/colors.tex` with your own definitions.

## frontmatter (books)

```yaml
frontmatter:
  - cover
  - title
  - copyright
  - preface
  - introduction
```

Sync only generates these files if they don't already exist.
Write your own `frontmatter/preface.tex` and sync won't touch it.

## copyright

```yaml
copyright:
  type: cc-by-sa      # cc-by-sa | cc-by | cc-by-nc | mit | none
  year: "auto"        # or a specific year: "2026"
  holder: "Your Name"
```

## cover (books)

```yaml
cover:
  type: generated     # generated | none
  generated:
    style: modern     # modern | classic | minimal
```

Or use your own: write `frontmatter/cover.tex` and set `type: none`.
