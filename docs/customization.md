# Customization Guide

How to customize and extend Papyrxis for your specific needs.

## Overview

Papyrxis provides three levels of customization:

1. Configuration (workspace.yml) - No code, just settings
2. Component overrides - Replace specific components with your versions
3. Direct modification - Edit .tex files in your project

Most needs are met with configuration and overrides. Direct modification is for special cases.

## Configuration-Based Customization

The easiest way to customize. Edit workspace.yml.

### Changing Colors

Use a predefined scheme:

```yaml
colors:
  scheme: academic  # or technical
```

Or define custom colors:

```yaml
colors:
  scheme: custom
  custom:
    primary: "25,45,85"      # Dark blue
    accent: "220,50,50"      # Red
    text: "20,20,20"         # Almost black
    textsecondary: "100,100,100"
```

Colors are RGB values (0-255).

### Selecting Components

Choose which components to load:

```yaml
components:
  - fonts
  - math
  - graphics
  - colors
  - layout
  # Add or remove as needed
```

See configuration.md for complete list.

### Adjusting Features

For books:

```yaml
features:
  toc: true           # Table of contents
  index: true         # Index
  bibliography: true  # Bibliography
  appendix: true      # Appendix
```

### Front Matter

Control what appears before main content:

```yaml
frontmatter:
  - cover
  - title
  - copyright
  - preface
  - introduction
```

Order matters. These appear in the sequence listed.

## Component Overrides

Replace any component with your custom version.

### Setup

1. Create configs directory (or whatever you named it):

```bash
mkdir -p configs
```

2. Add components you want to override to workspace.yml:

```yaml
overrides:
  components_dir: "configs"
  allow:
    - colors.tex
    - commands/base.tex
    - pagestyles.tex
```

3. Create your custom component:

```bash
# Example: custom colors
touch configs/colors.tex
```

4. Edit your component with custom content

5. Run sync:

```bash
make sync
```

Your custom component is now used instead of the default.

### What Can Be Overridden

Any component from common/components/:

Layout and typography:
- colors.tex
- layout.tex
- titles.tex
- pagestyles.tex

Environments:
- env.tex
- boxes.tex

Commands:
- commands/base.tex

Front matter:
- frontmatter/title.tex
- frontmatter/copyright.tex
- frontmatter/cover.tex

Others:
- index.tex
- bibliography.tex

And more. Check common/components/ for complete list.

### Override Examples

#### Example 1: Custom Colors

Create configs/colors.tex:

```latex
\usepackage{xcolor}

% Define your color scheme
\definecolor{primary}{RGB}{30,60,90}      % Navy blue
\definecolor{accent}{RGB}{200,100,50}     % Orange
\definecolor{subtle}{RGB}{240,245,250}    % Light blue
\definecolor{textprimary}{RGB}{20,20,20}
\definecolor{textsecondary}{RGB}{90,90,90}
\definecolor{border}{RGB}{180,180,180}
\definecolor{pagebackground}{RGB}{255,255,255}
\definecolor{codebackground}{RGB}{245,245,245}
```

Enable in workspace.yml:

```yaml
overrides:
  allow:
    - colors.tex
```

#### Example 2: Custom Commands

Create configs/commands/base.tex:

```latex
% Your custom commands
\newcommand{\important}[1]{\textbf{\color{accent}#1}}
\newcommand{\code}[1]{\texttt{#1}}
\newcommand{\note}[1]{\textit{\color{textsecondary}Note: #1}}

% Custom math operators
\DeclareMathOperator{\rank}{rank}
\DeclareMathOperator{\trace}{tr}

% Custom environments
\newenvironment{aside}{%
  \begin{quote}\small\itshape%
}{%
  \end{quote}%
}
```

Enable:

```yaml
overrides:
  allow:
    - commands/base.tex
```

Use in document:

```latex
This is \important{very important}.

Some \code{code text} here.

\note{This is a side note.}
```

#### Example 3: Custom Page Style

Create configs/pagestyles.tex:

```latex
\usepackage{fancyhdr}

% Simple page style
\fancypagestyle{main}{%
  \fancyhf{}
  \fancyhead[L]{\leftmark}
  \fancyhead[R]{\thepage}
  \renewcommand{\headrulewidth}{0.4pt}
}

\pagestyle{main}
```

Enable:

```yaml
overrides:
  allow:
    - pagestyles.tex
```

#### Example 4: Custom Title Page

Create configs/frontmatter/title.tex:

```latex
\begin{titlepage}
\centering
\vspace*{2cm}

{\Huge\bfseries {{TITLE}}\par}
\vspace{2cm}

{\Large {{AUTHOR}}\par}
\vspace{1cm}

{\large \today\par}

\vfill

{\small {{URL}}\par}

\end{titlepage}
```

Note the placeholders: {{TITLE}}, {{AUTHOR}}, {{URL}}. These are replaced during sync.

Enable:

```yaml
overrides:
  allow:
    - frontmatter/title.tex
```

## Creating Custom Environments

Add custom environments in configs/env.tex or configs/boxes.tex.

Example - Alert box:

```latex
\usepackage{tcolorbox}
\tcbuselibrary{most}

\newtcolorbox{alertbox}[1][Alert]{%
  colback=red!5!white,
  colframe=red!75!black,
  title=#1,
  fonttitle=\bfseries,
  sharp corners,
  boxrule=2pt,
  left=10pt,
  right=10pt,
  top=10pt,
  bottom=10pt,
  breakable
}
```

Use in document:

```latex
\begin{alertbox}[Warning]
This is an alert message.
\end{alertbox}
```

## Custom Color Schemes

Define a complete custom scheme.

Create configs/colors.tex:

```latex
\usepackage{xcolor}
\usepackage{xstring}

\makeatletter

% Define your scheme
\defineColorScheme{myscheme}
\defineSchemeColor{myscheme}{primary}{10,20,30}
\defineSchemeColor{myscheme}{accent}{200,50,50}
\defineSchemeColor{myscheme}{subtle}{240,245,250}
\defineSchemeColor{myscheme}{text}{15,15,15}
\defineSchemeColor{myscheme}{textsecondary}{80,80,80}
\defineSchemeColor{myscheme}{border}{170,170,170}
\defineSchemeColor{myscheme}{background}{255,255,255}
\defineSchemeColor{myscheme}{code}{248,250,252}

% Apply your scheme
\applyColorScheme{myscheme}

\makeatother
```

Enable:

```yaml
colors:
  scheme: custom  # Tells system not to apply default

overrides:
  allow:
    - colors.tex
```

## Custom Fonts

Override the fonts component.

Create configs/fonts.tex:

```latex
% Use different font package
\usepackage{charter}    % Body text
\usepackage{helvet}     % Sans serif
\usepackage{beramono}   % Monospace

\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage{microtype}
```

Or for XeLaTeX/LuaLaTeX:

```latex
\usepackage{fontspec}

\setmainfont{Libertinus Serif}
\setsansfont{Libertinus Sans}
\setmonofont{Inconsolata}

\usepackage{microtype}
```

Change engine in workspace.yml:

```yaml
build:
  engine: xelatex
```

Enable override:

```yaml
overrides:
  allow:
    - fonts.tex
```

## Custom Theorems and Definitions

Add to configs/commands/base.tex:

```latex
\usepackage{amsthm}

% Theorem styles
\theoremstyle{plain}
\newtheorem{theorem}{Theorem}[section]
\newtheorem{lemma}[theorem]{Lemma}
\newtheorem{corollary}[theorem]{Corollary}

\theoremstyle{definition}
\newtheorem{definition}[theorem]{Definition}
\newtheorem{example}[theorem]{Example}

\theoremstyle{remark}
\newtheorem{remark}[theorem]{Remark}
```

Use:

```latex
\begin{theorem}
Every even number greater than 2 can be expressed as the sum of two primes.
\end{theorem}

\begin{proof}
Proof goes here.
\end{proof}
```

## Custom Listings Style

Add to configs/code.tex:

```latex
\usepackage{listings}
\usepackage{xcolor}

\lstset{
  basicstyle=\ttfamily\small,
  keywordstyle=\color{blue}\bfseries,
  commentstyle=\color{green!60!black}\itshape,
  stringstyle=\color{red},
  frame=single,
  breaklines=true,
  numbers=left,
  numberstyle=\tiny\color{gray},
  captionpos=b,
  escapeinside={(*@}{@*)},
  backgroundcolor=\color{gray!5}
}
```

## Modifying Build Process

Override Makefile targets.

Add to your Makefile after the default targets:

```makefile
# Custom targets
.PHONY: draft release

draft:
	@echo "Building draft..."
	@sed -i 's/\\documentclass\[/\\documentclass[draft,/' main.tex
	@$(MAKE) build
	@git checkout main.tex

release:
	@echo "Building release..."
	@$(MAKE) clean
	@$(MAKE) build
	@cp build/main.pdf release-$(shell date +%Y%m%d).pdf
```

Use:

```bash
make draft
make release
```

## Template Placeholders

When creating custom frontmatter, use these placeholders:

- {{TITLE}} - Project title
- {{AUTHOR}} - Author name
- {{EMAIL}} - Author email
- {{URL}} - Project URL

These are replaced during sync.

Example:

```latex
\begin{titlepage}
\centering
{\Huge {{TITLE}}}

by {{AUTHOR}}

\url{{{URL}}}
\end{titlepage}
```

## Testing Overrides

After creating custom components:

1. Run sync:

```bash
make sync
```

Check output for:
- "Using override: component-name" - Success
- Warnings about disallowed overrides - Add to allow list

2. Build:

```bash
make
```

3. Check result in build/main.pdf

4. If needed, adjust and repeat

## Override Best Practices

Start small:
- Override one component at a time
- Test after each change
- Keep original as reference

Document changes:
- Comment your custom code
- Note what you changed and why
- Keep a changelog

Version control:
- Commit working overrides
- Tag stable versions
- Easy to revert if needed

Stay compatible:
- Follow Papyrxis naming conventions
- Use same color names (primary, accent, etc.)
- Maintain expected commands and environments

## When Not to Override

You do not need to override for:

- Adding sections/chapters - Just edit .tex files
- Changing text - Edit content files
- Small adjustments - Use workspace.yml configuration
- Temporary changes - Edit .tex directly

Override when:

- You need systematic changes
- You want reusable components
- You need different structure
- Default behavior does not fit

## Getting Help

If your override does not work:

1. Check syntax - Run LaTeX directly to see errors
2. Check paths - Files must be in correct directories
3. Check allow list - Component must be allowed
4. Check dependencies - Some components need others
5. Check examples - See working overrides in docs

For questions, open an issue or discussion on GitHub.

## Examples Repository

See the examples/ directory in the workspace repository for:

- Complete override examples
- Different customization approaches
- Tested and working configurations

These examples are a good starting point for your customizations.

## Summary

Customization workflow:

1. Edit workspace.yml for simple changes
2. Create override in configs/ for component changes
3. Add to allow list in workspace.yml
4. Run make sync
5. Build and test

Most customization happens through configuration and overrides. This keeps your project clean and maintainable.