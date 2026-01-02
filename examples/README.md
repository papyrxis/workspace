# Examples

Working examples demonstrating Papyrxis features and capabilities.

## Overview

This directory contains complete, working examples of documents built with Papyrxis. Each example demonstrates specific features or use cases.

Examples are self-contained and can be built independently.

## Available Examples

### workspace.config.yml

Template configuration file showing all available options with explanations.

Purpose:
- Reference for all configuration options
- Shows default values
- Explains each setting
- Copy and modify for your projects

Usage:
```bash
cp examples/workspace.config.yml my-project/workspace.yml
# Edit workspace.yml for your needs
```

## Planned Examples

The following examples are planned for future releases:

### Technical Book Example

Complete technical book with:
- Multiple parts and chapters
- Code listings
- Diagrams
- Index and bibliography
- Custom environments

Location: examples/technical-book/

### Academic Paper Example

IEEE-format academic paper with:
- Two-column layout
- Mathematical content
- Figures and tables
- Citations and references

Location: examples/academic-paper/

### Minimal Book Example

Simplest possible book:
- Single part
- Few chapters
- Minimal front matter
- Shows bare essentials

Location: examples/minimal-book/

### Custom Styling Example

Book with extensive customization:
- Custom color scheme
- Custom fonts
- Custom environments
- Override examples

Location: examples/custom-styling/

### Multilingual Example

Document with multiple languages:
- Font setup for different scripts
- Babel configuration
- Proper hyphenation
- Bibliography in multiple languages

Location: examples/multilingual/

## Using Examples

### Exploring Examples

Browse the examples/ directory to see different approaches and configurations.

### Building Examples

Each example can be built:

```bash
cd examples/technical-book
make
```

Output in build/main.pdf

### Copying Examples

To use an example as starting point:

```bash
# Copy example to new location
cp -r examples/technical-book my-book

# Remove git history (if example is tracked)
rm -rf my-book/.git

# Initialize your own git repo
cd my-book
git init

# Customize workspace.yml
vim workspace.yml

# Build
make
```

### Modifying Examples

Examples are meant to be modified:

1. Copy example
2. Edit workspace.yml for your needs
3. Update content files
4. Add/remove parts as needed
5. Build and test

## Example Structure

Each example typically includes:

```
example-name/
├── workspace.yml      # Configuration
├── main.tex          # Document entry
├── Makefile          # Build commands
├── README.md         # Example documentation
├── parts/            # Content (books)
├── frontmatter/      # Front matter (books)
├── figures/          # Images
├── references/       # Bibliography
└── configs/          # Custom overrides (if any)
```

## Example Categories

Examples organized by:

**Document Type:**
- Books
- Articles
- Reports

**Purpose:**
- Technical documentation
- Academic writing
- Theses
- Presentations

**Complexity:**
- Minimal (simple structure)
- Standard (typical usage)
- Advanced (custom features)

## Learning from Examples

Best way to learn Papyrxis:

1. Read getting-started.md for basics
2. Look at minimal examples to understand structure
3. Explore standard examples for typical usage
4. Study advanced examples for customization
5. Copy closest match to your needs
6. Modify for your project

## Contributing Examples

To contribute an example:

1. Create complete working example
2. Include comprehensive README
3. Test build process
4. Document special features
5. Submit pull request

Good examples are:
- Complete and working
- Well documented
- Demonstrate specific features
- Typical of real use case
- Include source comments

## Example Testing

Examples should build without errors:

```bash
# Test all examples
cd examples
for dir in */; do
    echo "Testing $dir"
    (cd "$dir" && make) || echo "Failed: $dir"
done
```

Maintainers run this test regularly to ensure examples stay working.

## Example Documentation

Each example should include README.md with:

- Purpose of example
- Features demonstrated
- Prerequisites
- Build instructions
- Customization notes
- Key files explained

## Example Best Practices

When creating examples:

**Keep it focused:**
- One main concept per example
- Do not mix too many features
- Clear purpose

**Make it complete:**
- All files needed to build
- No missing dependencies
- Working out of box

**Document it well:**
- README explains everything
- Comments in source files
- Expected output described

**Test it:**
- Build from clean state
- Verify output
- Check for errors

## Common Example Patterns

### Example workspace.yml

Most examples include annotated workspace.yml:

```yaml
# Project metadata
project:
  type: book
  category: technical
  title: "Example Title"
  # ...

# Component selection
components:
  - fonts
  - math
  # Only what this example needs

# Custom settings for demonstration
colors:
  scheme: custom
  custom:
    primary: "30,40,50"
```

### Example main.tex

Typical structure:

```latex
\documentclass[12pt,oneside]{book}

% Metadata
\newcommand{\PDFTitle}{Example Title}
% ...

% Import preset
\input{.pxis/preset}

\begin{document}
% Content organization
\frontmatter
\input{frontmatter/title}
% ...

\mainmatter
\input{parts/part01/part01}

\backmatter
\printbibliography
\end{document}
```

### Example README.md

Template:

```markdown
# Example Name

Brief description.

## Purpose

What this example demonstrates.

## Features

- Feature 1
- Feature 2

## Building

    make

## Customization

How to adapt for your needs.

## Files

- file1.tex - Purpose
- file2.tex - Purpose
```

## Troubleshooting Examples

**Example does not build**
- Update workspace submodule: git submodule update
- Check TeX installation: pdflatex --version
- Read example README for requirements

**Missing packages**
- Install full TeX Live
- Check system-specific requirements

**Output looks different**
- Font availability varies by system
- Graphics may render differently
- Check example documentation

## Related Documentation

See also:
- docs/getting-started.md - Setup and usage
- docs/templates.md - Template system
- docs/customization.md - Customizing documents
- docs/configuration.md - Configuration reference