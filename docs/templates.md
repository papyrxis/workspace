# Template System

Understanding and using Papyrxis templates.

## Overview

Papyrxis includes ready-to-use templates for books and articles. Templates provide structure, boilerplate, and examples to start quickly.

## Template Structure

Templates live in template/ directory:

```
template/
├── books/
│   ├── main.tex
│   ├── Makefile
│   ├── frontmatter/
│   ├── backmatter/
│   └── parts/
└── article/
    ├── ieee/
    ├── single-column/
    └── two-column/
```

## Book Templates

### Main Structure

template/books/main.tex provides complete document structure:

```latex
\documentclass[12pt,oneside,openany]{book}

% Metadata commands
\newcommand{\PDFTitle}{Book Title}
\newcommand{\PDFAuthor}{Author Name}
% ... more metadata

% Import preset
\input{.pxis/preset}

\begin{document}

\frontmatter
% Front matter sections

\mainmatter
% Main content

\backmatter
% Back matter

\end{document}
```

### Front Matter Templates

Included front matter:

preface.tex:
- Standard preface structure
- Sections for motivation, target audience, acknowledgments
- Signature block

introduction.tex:
- Introduction structure
- What/why/how sections
- Prerequisites
- Reading guide

acknowledgments.tex:
- Thank you section
- Placeholder text

### Part Template

template/books/parts/part01.tex:

```latex
\part{Part Title}
\label{part:part01}

\begin{partintro}
Overview of this part.
\end{partintro}

\chapter{Chapter Title}
\label{ch:chapter01}

\begin{chapterintro}
Chapter introduction.
\end{chapterintro}

\section{Section}
Content here.
```

Shows:
- Part/chapter structure
- Label conventions
- Intro environments
- Section organization

### Back Matter Templates

template/books/backmatter/:

appendix.tex:
- Appendix structure
- Multiple sections
- Additional resources

Standard sections:
- Additional background
- Code examples
- Solutions
- Further reading

## Article Templates

Three article templates for different needs.

### IEEE Template

template/article/ieee/main.tex:

```latex
\documentclass[10pt,a4paper]{article}

\input{../../common/presets/article/ieee}

\title{Article Title}

\author{
  \textbf{First Author}\\
  Institution\\
  email@example.com
  \and
  \textbf{Second Author}\\
  Institution\\
  email@example.com
}

\begin{document}
\maketitle

\begin{abstract}
Abstract here.
\end{abstract}

\keywords{keywords here}

\section{Introduction}
% ...
```

Features:
- IEEE two-column format
- Multiple authors
- Keywords command
- Standard sections

Use for:
- Conference papers
- IEEE submissions
- Two-column academic papers

### Single Column Template

template/article/single-column/main.tex:

```latex
\documentclass[12pt,a4paper]{article}

\input{../../../common/presets/article/technical}

\title{Article Title}
\author{Author Name}
\date{\today}

\begin{document}
\maketitle

\begin{abstract}
Abstract here.
\end{abstract}

\section{Introduction}
% ...
```

Features:
- Single column
- Technical style
- Simpler layout

Use for:
- Technical reports
- Working papers
- Documentation

### Two Column Template

template/article/two-column/main.tex:

Similar to IEEE but with more flexibility.

Use for:
- Custom two-column documents
- Non-IEEE conferences
- Technical articles

## Using Templates

### During Initialization

Templates are used automatically:

```bash
bash workspace/scripts/init.sh -t book --title "My Book"
```

This:
1. Copies appropriate template
2. Substitutes your title, author, etc.
3. Sets up directory structure
4. Creates initial files

### Manual Template Use

Copy template manually:

```bash
# Copy book template
cp workspace/template/books/main.tex .
cp -r workspace/template/books/frontmatter .
cp -r workspace/template/books/parts .

# Copy article template
cp workspace/template/article/ieee/main.tex .
```

Then edit to customize.

### Starting from Scratch

You can also start with minimal structure and add components manually. Templates are optional.

## Template Variables

Templates use placeholder variables replaced during initialization:

- {{TITLE}} → project.title
- {{AUTHOR}} → project.author
- {{EMAIL}} → project.email
- {{URL}} → project.url

Example in template:

```latex
\newcommand{\PDFTitle}{{{TITLE}}}
\newcommand{\PDFAuthor}{{{AUTHOR}}}
```

After substitution:

```latex
\newcommand{\PDFTitle}{My Book}
\newcommand{\PDFAuthor}{John Smith}
```

## Customizing Templates

### For Your Project

After initialization, edit generated files:

```
main.tex            - Structure
frontmatter/*.tex   - Front matter
parts/*/*.tex       - Content
```

Templates provide starting point. You modify for your needs.

### Creating New Templates

To create reusable templates:

1. Create directory in template/:

```bash
mkdir -p template/mytemplate
```

2. Add template files:

```
template/mytemplate/
├── main.tex
├── Makefile
└── structure/
```

3. Use placeholders for dynamic content:

```latex
\title{{{TITLE}}}
\author{{{AUTHOR}}}
```

4. Update init.sh to support your template (advanced).

## Template Components

Templates coordinate these pieces:

Document class:
- Book: report or book class
- Article: article class with options

Preset import:
```latex
\input{.pxis/preset}
```

Loads synced components based on workspace.yml.

Document structure:
- \frontmatter, \mainmatter, \backmatter for books
- Sections for articles

Content organization:
- Input statements for separate files
- Logical structure

Metadata:
- Title, author, etc.
- Used in title pages, headers, PDF metadata

## Template Best Practices

Keep it simple:
- Templates should be straightforward
- Avoid complex logic
- Provide clear examples

Use comments:
- Explain what each section does
- Note customization points
- Link to documentation

Follow conventions:
- Use standard LaTeX structure
- Follow naming patterns
- Be consistent

Make it extensible:
- Easy to add sections
- Easy to remove parts
- Clear where to customize

## Template Maintenance

Templates are maintained in the workspace repository. When you update the workspace submodule, templates update too.

Your generated files do not change. Templates only affect new initializations.

To update existing project to new template:
- Manually compare and merge changes
- Or regenerate in new directory and copy content

## Examples

### Example 1: Starting a Technical Book

```bash
bash workspace/scripts/init.sh \
  -t book \
  -c technical \
  --title "System Design" \
  --author "Your Name"
```

Gets:
- Book template with technical styling
- Front matter (preface, intro)
- First part and chapter
- Ready to write

### Example 2: Starting IEEE Paper

```bash
bash workspace/scripts/init.sh \
  -t article \
  -c academic \
  --title "My Research"
```

Gets:
- IEEE format
- Two columns
- Abstract and keywords
- Standard sections

### Example 3: Starting from Minimal

Edit workspace.yml manually, create main.tex yourself, then:

```bash
make sync
make
```

No template needed. Full control.

## Template Troubleshooting

### Template Variables Not Replaced

Check that workspace.yml has correct values:

```yaml
project:
  title: "My Title"
  author: "My Name"
```

Run sync:

```bash
make sync
```

### Wrong Template Used

init.sh selects template based on type and category. Check your options:

```bash
bash workspace/scripts/init.sh -t book -c technical
```

### Missing Files

If template references missing files, either:
- Create the file
- Remove the reference
- Use a different template

### Build Errors

Template might use components you do not have. Check workspace.yml:

```yaml
components:
  - fonts
  - math
  # ... ensure all needed components listed
```

## Template Locations

Book templates:
- template/books/ - Main template
- workspace/template/books/ - In workspace submodule

Article templates:
- template/article/ieee/ - IEEE format
- template/article/single-column/ - Single column
- template/article/two-column/ - Two column

Component templates:
- common/frontmatter/ - Front matter
- common/presets/ - Document presets

## Creating Project-Specific Templates

For repeated similar projects, create your own templates:

1. Complete one project
2. Remove content, keep structure
3. Add placeholders
4. Save as template
5. Reuse for new projects

Example structure:

```
my-templates/
├── book/
│   ├── main.tex
│   ├── workspace.yml
│   └── structure/
└── article/
    └── main.tex
```

Copy and customize for each new project.

## Summary

Templates provide:
- Starting point
- Best practices
- Working examples
- Time savings

Use templates to:
- Start new projects quickly
- Follow conventions
- Learn structure
- Avoid mistakes

Customize templates by:
- Editing generated files
- Overriding components
- Creating new templates

Templates are optional. You have full control over your document structure.