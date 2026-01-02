# Packages

LaTeX package loading and basic configuration.

## Overview

This directory contains package loading files. Each file loads related packages and provides minimal configuration.

Package files are simpler than components. They just load packages and set basic options. Components build on top of packages to provide functionality.

## Package Files

### fonts.tex

Loads font packages and encoding:

```latex
\usepackage{lmodern}
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage{microtype}
```

Provides:
- Latin Modern fonts
- T1 font encoding (better for European languages)
- UTF-8 input encoding
- Micro-typographic improvements

### math.tex

Loads math packages and defines operators:

```latex
\usepackage{mathtools}
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{amsthm}
\usepackage{bm}
```

Provides:
- Enhanced math environments
- Math symbols
- Theorem environments
- Bold math
- Paired delimiters: \floor, \ceil, \abs, \norm
- Operators: \argmin, \argmax, \poly, \polylog, \lcm

### graphics.tex

Loads graphics and diagram packages:

```latex
\usepackage{graphicx}
\usepackage{caption}
\usepackage{subcaption}
\usepackage{tikz}
\usepackage{pdfpages}
```

Provides:
- Image inclusion
- Caption formatting
- Subfigures
- TikZ diagrams with positioning, shapes, arrows
- PDF page inclusion

### tables.tex

Loads table packages:

```latex
\usepackage{array}
\usepackage{multicol}
\usepackage{booktabs}
```

Provides:
- Enhanced table formatting
- Column types
- Multi-column support
- Professional table rules

### code.tex

Loads code listing packages:

```latex
\usepackage{listings}
\usepackage{algorithm}
\usepackage{algpseudocode}
```

Provides:
- Code listings with syntax highlighting
- Algorithm environments
- Pseudocode formatting
- Customizable styles

Basic listings configuration included.

### bibliography.tex

Loads bibliography package:

```latex
\usepackage[backend=biber,style=authoryear]{biblatex}
```

Provides:
- Modern bibliography with biblatex
- Biber backend
- Author-year citation style

### hyperref.tex

Loads hyperref for PDF features:

```latex
\usepackage{hyperref}
\hypersetup{
  pdfauthor={Author},
  pdftitle={Title},
  pdfsubject={Subject},
  pdfkeywords={Keywords}
}
```

Provides:
- Clickable links in PDF
- PDF metadata
- Internal cross-references
- URL support

Note: Actual metadata filled in during sync from workspace.yml.

## Package Loading Order

Order matters for some packages. Current order is safe:

1. fonts (encoding first)
2. math (needs encoding)
3. graphics
4. tables
5. code
6. bibliography
7. hyperref (should be last)

Components (colors, layout, etc.) come after packages.

## Using Packages

Packages are loaded automatically based on workspace.yml:

```yaml
components:
  - fonts
  - math
  - graphics
```

Package files are treated like components - copied to .pxis/ and loaded.

## Package vs Component

When to create package file vs component:

**Package file** when:
- Just loading packages
- Minimal configuration
- Widely used combination

**Component file** when:
- Defining commands
- Creating environments
- Complex configuration
- Building on packages

Example:
- fonts.tex (package) loads lmodern
- colors.tex (component) loads xcolor and defines color schemes

## Customizing Packages

To use different packages:

1. Create custom package file in configs/:

```latex
% configs/fonts.tex
\usepackage{charter}    % Different font
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
```

2. Add to workspace.yml:

```yaml
overrides:
  allow:
    - fonts.tex
```

3. Run make sync

## Package Options

Some packages have options. Configure in package file:

Example - Different bibliography style:

```latex
% configs/bibliography.tex
\usepackage[backend=biber,style=numeric]{biblatex}
```

Example - Different hyperlink colors:

```latex
% configs/hyperref.tex
\usepackage{hyperref}
\hypersetup{
  colorlinks=true,
  linkcolor=black,
  citecolor=black,
  urlcolor=blue
}
```

## Adding New Packages

To add new package file:

1. Create packagename.tex in this directory
2. Load related packages
3. Add minimal configuration
4. Test with sample document
5. Document here

Example - Adding glossary support:

```latex
% glossary.tex
\usepackage[acronym,toc]{glossaries}
\makeglossaries
```

Then users can add to workspace.yml:

```yaml
components:
  - glossary
```

## Common Package Combinations

For technical books:
- fonts, math, graphics, tables, code, bibliography

For academic papers:
- fonts, math, graphics, tables, bibliography

For theses:
- fonts, math, graphics, tables, code, bibliography
- Plus custom packages for university requirements

## Package Dependencies

Some packages need others:

- hyperref should be loaded last (already is)
- graphicx needed for includegraphics
- caption needed for subcaption
- amsmath needed for mathtools

Current package files handle dependencies correctly.

## Package Conflicts

Some packages conflict. Avoid loading:

- Both geometry and fullpage
- Both times and lmodern (different font packages)
- Multiple bibliography systems

Package files are designed to avoid conflicts.

## Troubleshooting

**Package not found**
- Install full TeX Live or MiKTeX
- Check package name spelling
- Update TeX distribution

**Option clash**
- Package loaded twice with different options
- Check for duplicates in components list
- Remove duplicate, use one with all options

**Package conflicts**
- Some packages cannot coexist
- Check package documentation
- Choose one or the other

**Missing package on system**
- Install with TeX package manager
- Or remove from package file
- Or install manually

## Platform-Specific Packages

Some packages work differently on different systems:

- Font packages on Windows vs Linux/Mac
- Graphics formats
- System fonts with XeLaTeX/LuaLaTeX

Package files use portable options. For system-specific needs, create custom package file.

## Package Versions

TeX Live includes specific package versions. Some features need newer versions.

If package errors mention version:
- Update TeX distribution
- Check package documentation for version requirements
- Or avoid feature requiring newer version

## Best Practices

Package loading:
- Load only needed packages
- Use minimal options
- Let components add functionality
- Keep it simple

Package configuration:
- Minimal in package file
- Detailed in components
- User overrides in configs/

Documentation:
- Document loaded packages
- Note important options
- Explain dependencies

## Related Documentation

See also:
- docs/configuration.md - Configuring components
- docs/customization.md - Custom package files
- common/components/README.md - Component system