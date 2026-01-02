# Configuration Reference

Complete reference for workspace.yml configuration options.

## File Format

workspace.yml is a YAML file. YAML basics:

- Indentation matters (use 2 spaces)
- Strings can be quoted or unquoted
- Lists use hyphens
- Comments start with #

Example structure:

```yaml
project:
  type: book
  title: "My Book"

components:
  - fonts
  - math

colors:
  scheme: technical
```

## Project Section

Basic project metadata.

### project.type

Document type.

Values: `book` or `article`

```yaml
project:
  type: book
```

Determines:
- Which components are included by default
- Document structure (parts vs sections)
- Available features

Required: Yes

### project.category

Document category/style.

Values: `technical` or `academic`

```yaml
project:
  category: technical
```

Affects:
- Default color scheme
- Typography choices
- Component defaults
- Preset selection

Default: technical

### project.title

Document title.

```yaml
project:
  title: "My Book Title"
```

Used in:
- PDF metadata
- Title page
- Headers (if configured)
- Cover page

Required: Yes

### project.subtitle

Document subtitle (optional).

```yaml
project:
  subtitle: "A Comprehensive Guide"
```

Used in:
- Title page
- Cover page (if enabled)

Default: empty

### project.author

Author name.

```yaml
project:
  author: "John Smith"
```

Used in:
- PDF metadata
- Title page
- Copyright page
- Cover page

Required: Yes

### project.email

Author email (optional).

```yaml
project:
  email: "john@example.com"
```

Used in:
- Title page (if template supports it)

Default: empty

### project.date

Document date.

Values: `auto` or specific date string

```yaml
project:
  date: "auto"
  # or
  date: "2024-01-15"
```

auto: Uses LaTeX \today command
Specific date: Fixed date

Default: auto

### project.url

Project URL.

```yaml
project:
  url: "https://github.com/user/repo"
```

Used in:
- Copyright page
- Title page footer
- PDF metadata

Default: empty

### project.subject

Document subject (optional).

```yaml
project:
  subject: "Computer Science"
```

Used in:
- PDF metadata

Default: empty

### project.keywords

Document keywords (optional).

```yaml
project:
  keywords: "latex, book, computer science"
```

Used in:
- PDF metadata

Default: empty

## Build Section

Build process configuration.

### build.engine

LaTeX engine to use.

Values: `pdflatex`, `xelatex`, or `lualatex`

```yaml
build:
  engine: pdflatex
```

Recommendations:
- pdflatex: fastest, most compatible
- xelatex: better font support
- lualatex: advanced features

Default: pdflatex

### build.bibtex

Bibliography processor.

Values: `biber` or `bibtex`

```yaml
build:
  bibtex: biber
```

Recommendations:
- biber: modern, recommended
- bibtex: legacy, more compatible

Default: biber

### build.output_dir

Output directory for build artifacts.

```yaml
build:
  output_dir: build
```

All temporary files and final PDF go here.

Default: build

### build.watch_mode

Enable watch mode by default (not commonly changed).

```yaml
build:
  watch_mode: true
```

Default: true

## Version Section

Version management configuration.

### version.source

Where to get version number.

Values: `git` or `manual`

```yaml
version:
  source: git
```

git: Use git describe --tags
manual: Use version.fallback always

Default: git

### version.format

Format for git-generated versions.

```yaml
version:
  format: "v{major}.{minor}.{patch}"
```

Placeholders:
- {major}, {minor}, {patch}: from git tags
- Custom text allowed

Only used if version.source is git.

Default: "v{major}.{minor}.{patch}"

### version.fallback

Version to use if git tags not available.

```yaml
version:
  fallback: "dev"
```

Used when:
- No git repository
- No git tags
- version.source is manual

Default: dev

## Components Section

Which components to include.

### components

List of components to load.

```yaml
components:
  - fonts
  - math
  - graphics
  - tables
  - colors
  - layout
```

Available components:

Core packages:
- fonts: Font configuration
- math: Math packages and operators
- graphics: Image and diagram support
- tables: Table formatting
- hyperref: PDF links and metadata

Layout and style:
- colors: Color scheme system
- layout: Page geometry and spacing
- titles: Section title formatting
- pagestyles: Header/footer styles

Content components:
- env: Special environments (keyidea, note, etc.)
- boxes: Colored boxes (notebox, warningbox, etc.)
- index: Index generation
- bibliography: Bibliography support
- code: Code listings and algorithms

Commands:
- commands/base: Base command definitions

Default for books:
- fonts, math, graphics, tables, hyperref
- colors, layout, titles, pagestyles
- env, index, bibliography, code, boxes
- commands/base

Default for articles:
- fonts, math, graphics, tables, hyperref
- colors, layout, bibliography, code
- commands/base

You can add or remove components. Order does not usually matter, but some components depend on others (colors must come before pagestyles).

## Features Section

Features for books only.

### features.toc

Include table of contents.

```yaml
features:
  toc: true
```

Default: true

### features.index

Include index.

```yaml
features:
  index: true
```

Requires index component.

Default: true

### features.bibliography

Include bibliography.

```yaml
features:
  bibliography: true
```

Requires bibliography component.

Default: true

### features.glossary

Include glossary.

```yaml
features:
  glossary: false
```

Not fully implemented yet.

Default: false

### features.appendix

Include appendix.

```yaml
features:
  appendix: true
```

Default: true

## Frontmatter Section

Front matter sections for books.

### frontmatter

List of front matter sections.

```yaml
frontmatter:
  - cover
  - title
  - copyright
  - preface
  - introduction
```

Available sections:

Generated:
- cover: Cover page (generated or PDF)
- title: Title page (generated)
- copyright: Copyright page (generated)

From files:
- preface: frontmatter/preface.tex
- acknowledgments: frontmatter/acknowledgments.tex
- introduction: frontmatter/introduction.tex

Order matters. Sections appear in the order listed.

Default for books:
- cover, title, copyright, preface, introduction

## Colors Section

Color scheme configuration.

### colors.scheme

Predefined color scheme.

Values: `technical`, `academic`, or `custom`

```yaml
colors:
  scheme: technical
```

technical:
- Primary: dark blue
- Accent: bright blue
- Professional look

academic:
- Primary: black
- Accent: dark gray
- Conservative look

custom:
- Use colors.custom definitions

Default: matches project.category

### colors.custom

Custom color definitions (when scheme is custom).

```yaml
colors:
  scheme: custom
  custom:
    primary: "30,40,50"
    accent: "0,86,179"
    text: "33,37,41"
```

All values are RGB triplets (0-255).

Available colors:
- primary: Main color for titles, etc.
- accent: Accent color for links, highlights
- subtle: Background tints
- text: Main text color
- textsecondary: Secondary text color
- border: Border and rule colors
- background: Page background
- code: Code block background

## Copyright Section

Copyright and license settings.

### copyright.type

License type.

Values: `cc-by-sa`, `cc-by`, `cc-by-nc`, `cc-by-nc-sa`, `mit`, `apache`, `custom`, or `none`

```yaml
copyright:
  type: cc-by-sa
```

cc-by-sa: Creative Commons Attribution-ShareAlike
cc-by: Creative Commons Attribution
cc-by-nc: Creative Commons Attribution-NonCommercial
cc-by-nc-sa: Creative Commons Attribution-NonCommercial-ShareAlike
mit: MIT License
apache: Apache License 2.0
custom: Use copyright.custom_text
none: No license statement

Default: cc-by-sa

### copyright.year

Copyright year.

Values: `auto` or specific year

```yaml
copyright:
  year: "auto"
  # or
  year: "2024"
```

auto: Current year
Specific year: Fixed year

Default: auto

### copyright.holder

Copyright holder name.

```yaml
copyright:
  holder: "John Smith"
```

Default: project.author

### copyright.custom_text

Custom license text (when type is custom).

```yaml
copyright:
  type: custom
  custom_text: "All rights reserved. Contact author for permissions."
```

Used only when type is custom.

Default: empty

## Cover Section

Cover page settings for books.

### cover.type

Cover type.

Values: `generated`, `pdf`, or `none`

```yaml
cover:
  type: generated
```

generated: Auto-generate cover from template
pdf: Use existing PDF file
none: No cover page

Default: generated

### cover.pdf_file

PDF file to use (when type is pdf).

```yaml
cover:
  type: pdf
  pdf_file: "my-cover.pdf"
```

File must exist in project root.

Default: cover.pdf

### cover.generated

Settings for generated covers.

```yaml
cover:
  type: generated
  generated:
    style: modern
    title_size: large
    include_subtitle: true
    include_author: true
```

#### cover.generated.style

Cover style template.

Values: `modern`, `classic`, or `minimal`

modern: Contemporary design with geometric elements
classic: Traditional academic style
minimal: Clean and simple

Default: modern

#### cover.generated.title_size

Title font size.

Values: `small`, `medium`, or `large`

Default: large

#### cover.generated.include_subtitle

Show subtitle on cover.

Values: `true` or `false`

Default: true

#### cover.generated.include_author

Show author on cover.

Values: `true` or `false`

Default: true

## Overrides Section

Component override configuration.

### overrides.components_dir

Directory for custom component overrides.

```yaml
overrides:
  components_dir: "configs"
```

Place your custom versions of components here.

Default: configs

### overrides.allow

List of components that can be overridden.

```yaml
overrides:
  allow:
    - colors.tex
    - commands/base.tex
    - pagestyles.tex
    - frontmatter/title.tex
```

Only components in this list can be overridden. This prevents accidental overrides and makes intentions clear.

If a file exists in components_dir but is not in the allow list, it will be ignored and a warning will be shown.

Default: empty list (no overrides)

## Complete Example

Full workspace.yml with all sections:

```yaml
# Project metadata
project:
  type: book
  category: technical
  title: "Advanced Algorithms"
  subtitle: "A Comprehensive Guide"
  author: "Jane Doe"
  email: "jane@example.com"
  date: "auto"
  url: "https://github.com/jane/algorithms-book"
  subject: "Computer Science"
  keywords: "algorithms, computer science, textbook"

# Build configuration
build:
  engine: pdflatex
  bibtex: biber
  output_dir: build
  watch_mode: true

# Version management
version:
  source: git
  format: "v{major}.{minor}.{patch}"
  fallback: "dev"

# Components to include
components:
  - fonts
  - math
  - graphics
  - tables
  - hyperref
  - code
  - bibliography
  - colors
  - layout
  - titles
  - pagestyles
  - env
  - boxes
  - index
  - commands/base

# Book features
features:
  toc: true
  index: true
  bibliography: true
  glossary: false
  appendix: true

# Front matter sections
frontmatter:
  - cover
  - title
  - copyright
  - preface
  - acknowledgments
  - introduction

# Color scheme
colors:
  scheme: technical

# Copyright settings
copyright:
  type: cc-by-sa
  year: "auto"
  holder: "Jane Doe"

# Cover settings
cover:
  type: generated
  generated:
    style: modern
    title_size: large
    include_subtitle: true
    include_author: true

# Component overrides
overrides:
  components_dir: "configs"
  allow:
    - colors.tex
    - commands/base.tex
    - pagestyles.tex
    - frontmatter/title.tex
```

## Validation

When you run make sync, configuration is validated:

- Required fields must exist
- Values must be valid
- Referenced files must exist
- Component dependencies are checked

Errors show which option is problematic and what the valid values are.

Warnings show non-critical issues like missing optional fields.

## Environment Variables

You can override some settings with environment variables:

```bash
VERSION=1.0.0 make
BUILD_DATE="2024-01-15" make
```

Available:
- VERSION: Override version
- BUILD_DATE: Override build date

These are temporary and do not change workspace.yml.

## Configuration Changes

After editing workspace.yml:

1. Run `make sync` to regenerate .pxis/
2. Run `make` to rebuild document

Or just `make` which runs sync automatically.

Changes take effect immediately.