# Customization

## Overriding a component

Create a `.tex` file in your `configs/` directory with the same name as the component:

```
configs/
├── colors.tex          # replaces common/components/colors.tex
├── commands/
│   └── base.tex        # replaces common/components/commands/base.tex
└── bibliography.tex    # replaces common/packages/bibliography.tex
```

Run `make sync`. Done.

## Extending a component

If you want the default component plus your additions:

```yaml
overrides:
  dir: "configs"
  mode: extend
```

With `extend`, the default loads first, then your file is appended.
This is useful for adding custom commands on top of `commands/base.tex`
without copying the whole thing.

## Adding your own components

Place any `.tex` file in `configs/` that doesn't match an existing component name,
and add it to the `components` list in `workspace.yml`:

```yaml
components:
  - fonts
  - math
  # ...
  - mycomponent       # configs/mycomponent.tex
```

## Custom bibliography style

For numeric citations (e.g. [1], [2]):

```tex
% configs/bibliography.tex
\usepackage[
  backend=biber,
  style=numeric,
  sorting=none
]{biblatex}

\addbibresource{references/main.bib}
```

For footnote-heavy writing (books):

```tex
% configs/bibliography.tex  
\usepackage[
  backend=biber,
  style=authoryear,
  autocite=footnote
]{biblatex}

\addbibresource{references/main.bib}
```

## Colors

```tex
% configs/colors.tex
\usepackage{xcolor}

\definecolor{primary}{RGB}{20, 20, 20}
\definecolor{accent}{RGB}{0, 100, 200}
\definecolor{textsecondary}{RGB}{80, 80, 80}
```

No need to call `\applyColorScheme` — just define the colors directly.

## Frontmatter

Write your own `frontmatter/preface.tex` (or any other frontmatter file)
and sync won't overwrite it. That's the rule: **if the file exists, sync skips it**.
