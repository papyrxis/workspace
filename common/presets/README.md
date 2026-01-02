# Presets

Complete document presets combining components for specific document types.

## Overview

Presets are pre-configured combinations of components, packages, and settings for common document types. They provide a quick starting point with sensible defaults.

## Directory Structure

```
presets/
├── book/
│   ├── technical.tex
│   └── academic.tex
└── article/
    ├── technical.tex
    ├── academic.tex
    └── ieee.tex
```

## Book Presets

### book/technical.tex

For technical books and programming books.

Includes:
- Charter font (body), Helvet (sans), Beramono (mono)
- Full math support
- Code listings and algorithms
- Graphics and diagrams
- Colored links and elements
- Custom environments (keyidea, note, warning)
- Colored boxes
- Index and bibliography

Style characteristics:
- Modern, readable typography
- Color scheme: blue accent on dark primary
- Code-friendly formatting
- Technical theorem environments

Use for:
- Programming books
- Technical manuals
- Software documentation
- Computer science texts

### book/academic.tex

For academic books and textbooks.

Includes:
- Times font (traditional academic look)
- Complete math support (theorem environments)
- Graphics and tables
- Conservative styling
- Black and white color scheme
- Academic theorem/proof environments
- Index and bibliography

Style characteristics:
- Traditional typography
- Black on white
- Formal theorem environments
- Academic conventions

Use for:
- Academic textbooks
- Research monographs
- Scholarly books
- Traditional publications

## Article Presets

### article/technical.tex

For technical articles and reports.

Includes:
- Charter font (body)
- Math, code, graphics
- Single column
- Colored links
- Technical styling
- Colored boxes

Style characteristics:
- Modern readable typography
- Color accents
- Code-friendly
- Flexible layout

Use for:
- Technical reports
- Working papers
- Software documentation
- Internal documents

### article/academic.tex

For academic papers.

Includes:
- Times font
- Full math support
- Single column
- Conservative styling
- Black links
- Theorem environments

Style characteristics:
- Traditional typography
- Conservative formatting
- Academic conventions
- Formal proofs

Use for:
- Preprints
- Academic papers
- Research articles
- Journal submissions (as starting point)

### article/ieee.tex

For IEEE format papers.

Includes:
- Times font
- Two-column layout
- IEEE spacing and formatting
- Minimal math
- Standard sections

Style characteristics:
- IEEE conference paper format
- Two columns
- Compact spacing
- Standard IEEE style

Use for:
- IEEE conference submissions
- Two-column technical papers
- Following IEEE guidelines

Note: This is a starting point. Check specific conference requirements.

## Using Presets

### Automatic (Recommended)

Presets are selected automatically during initialization based on type and category:

```bash
bash workspace/scripts/init.sh -t book -c technical
```

Selects: book/technical.tex preset

```bash
bash workspace/scripts/init.sh -t article -c academic
```

Selects: article/academic.tex preset

### Manual

Import preset directly in main.tex:

```latex
\documentclass{book}
\input{workspace/common/presets/book/technical}
\begin{document}
...
\end{document}
```

Or for new workspace system:

```latex
\documentclass{book}
\input{.pxis/preset}  % Auto-generated from workspace.yml
\begin{document}
...
\end{document}
```

The new system (workspace.yml + sync) is preferred as it is more flexible.

## Preset Contents

Each preset typically includes:

1. Font setup (or imports font package)
2. Package imports (math, graphics, etc.)
3. Component imports (colors, layout, etc.)
4. Style configuration
5. Theorem environments (if applicable)
6. Color scheme application

Example structure:

```latex
% Fonts
\usepackage{charter}

% Packages
\input{common/packages/math}
\input{common/packages/graphics}

% Components
\input{common/components/colors}
\input{common/components/layout}

% Apply color scheme
\applyColorScheme{technical}

% Configure hyperref colors
\hypersetup{
  colorlinks=true,
  linkcolor=accent,
  citecolor=accent,
  urlcolor=accent
}
```

## Customizing Presets

Do not edit preset files directly. Instead:

### Option 1: Use workspace.yml

Configure components and colors:

```yaml
components:
  - fonts
  - math
  - graphics
  # Choose what you need

colors:
  scheme: technical
```

Run make sync and your custom preset is generated.

### Option 2: Create Custom Preset

1. Copy existing preset:

```bash
cp workspace/common/presets/book/technical.tex configs/my-preset.tex
```

2. Edit configs/my-preset.tex

3. Use in main.tex:

```latex
\input{configs/my-preset}
```

### Option 3: Layer Components

Start with preset, add components:

```latex
\input{.pxis/preset}  % Base preset
\input{configs/my-additions}  % Your additions
```

## Preset Comparison

### Book Presets

| Feature | Technical | Academic |
|---------|-----------|----------|
| Font | Charter | Times |
| Colors | Blue accent | Black/White |
| Code | Yes | No |
| Style | Modern | Traditional |
| Math | Basic | Full theorems |

### Article Presets

| Feature | Technical | Academic | IEEE |
|---------|-----------|----------|------|
| Font | Charter | Times | Times |
| Columns | 1 | 1 | 2 |
| Colors | Yes | Minimal | Minimal |
| Format | Flexible | Traditional | IEEE |

## Preset Dependencies

Presets depend on:
- Package files (common/packages/)
- Component files (common/components/)
- Font packages (from TeX distribution)

All dependencies must be available.

## Creating New Presets

To create new preset:

1. Choose base (book or article)
2. Create file: common/presets/type/name.tex
3. Include necessary packages and components
4. Configure style
5. Test with sample document
6. Document here

Example - Book preset for fiction:

```latex
% common/presets/book/fiction.tex
\usepackage{ebgaramond}  % Elegant font
\usepackage[T1]{fontenc}

\input{common/packages/graphics}
\input{common/components/layout}

% Fiction-specific settings
\setlength{\parindent}{2em}
\setlength{\parskip}{0pt}
% No headers/footers except page numbers
```

## Preset Selection Logic

When using workspace.yml, preset is selected:

```
If type=book and category=technical → book/technical.tex
If type=book and category=academic → book/academic.tex
If type=article and category=technical → article/technical.tex
If type=article and category=academic → article/academic.tex
```

Actually, new system does not use preset files directly. It generates .pxis/preset.tex from workspace.yml configuration. But understanding preset files helps understand what components are typically used together.

## Migrating Between Presets

To change preset after initialization:

1. Update workspace.yml:

```yaml
project:
  category: academic  # Was technical
```

2. Run sync:

```bash
make sync
```

3. Check result:

```bash
make
```

Your document now uses academic styling.

## Preset Best Practices

When using presets:
- Start with closest match
- Customize via workspace.yml
- Override specific components as needed
- Keep customizations organized

When creating presets:
- Include only necessary packages
- Use consistent naming
- Document purpose
- Test thoroughly

## Troubleshooting

**Preset not found**
- Check file path
- Verify workspace.yml type and category
- Run make sync

**Preset conflicts**
- Check for duplicate package loads
- Verify component compatibility
- Remove conflicting components

**Preset does not match needs**
- Use different category
- Or customize with workspace.yml
- Or create custom preset

**Build errors with preset**
- Check missing packages
- Verify TeX distribution
- Check preset dependencies

## Related Documentation

See also:
- docs/getting-started.md - Using presets
- docs/configuration.md - Configuring components
- common/components/README.md - Available components
- common/packages/README.md - Package system