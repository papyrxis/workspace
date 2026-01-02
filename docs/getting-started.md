# Getting Started with Papyrxis Workspace

Complete guide to setting up and using Papyrxis for LaTeX projects.

## What is Papyrxis?

Papyrxis is a modular LaTeX workspace system. It provides reusable components, sensible defaults, and automation for technical books and academic papers.

Think of it as a well-organized collection of LaTeX packages, components, and build tools that work together seamlessly.

## Prerequisites

Required tools:

- TeX Live or MiKTeX (full installation recommended)
- Git
- Bash (for build scripts)
- Make

Optional but helpful:

- Python 3 with PyYAML (for advanced config parsing)
- inotifywait or fswatch (for watch mode)

Check your installation:

```bash
pdflatex --version
biber --version
git --version
make --version
```

## Installation Methods

### Method 1: As a Git Submodule (Recommended)

Use Papyrxis as a submodule in your project. This keeps your project and workspace separate.

```bash
# Create your project directory
mkdir my-book
cd my-book
git init

# Add Papyrxis as submodule
git submodule add https://github.com/papyrxis/workspace.git

# Initialize project
bash workspace/scripts/init.sh -t book --title "My Book"
```

Benefits:
- Clean separation between your content and workspace
- Easy to update workspace independently
- Multiple projects can share one workspace

### Method 2: Direct Clone

Clone Papyrxis and work directly inside it.

```bash
# Clone repository
git clone https://github.com/papyrxis/workspace.git my-book
cd my-book

# Initialize your project
bash scripts/init.sh -t book --title "My Book"
```

Benefits:
- Simpler if you only have one project
- All files in one place

## Quick Start

### Creating a Book

Minimal setup:

```bash
bash workspace/scripts/init.sh -t book --title "My Book"
make
```

This creates:
- workspace.yml configuration
- main.tex entry point
- Directory structure (parts/, frontmatter/, etc.)
- Build system (Makefile)

With all options:

```bash
bash workspace/scripts/init.sh \
  -t book \
  -c technical \
  --title "My Technical Book" \
  --author "Your Name" \
  --email "you@example.com" \
  --url "https://github.com/user/repo"
```

Interactive mode (prompts for everything):

```bash
bash workspace/scripts/init.sh -t book --interactive
```

### Creating an Article

IEEE-style two-column:

```bash
bash workspace/scripts/init.sh \
  -t article \
  -c academic \
  --title "My Research Paper"
```

Single-column technical article:

```bash
bash workspace/scripts/init.sh \
  -t article \
  -c technical \
  --title "My Technical Article"
```

## Project Structure

After initialization, your project looks like this:

```
my-book/
├── workspace/              # Papyrxis submodule (if using submodule method)
├── workspace.yml          # Your configuration
├── main.tex              # Document entry point
├── Makefile              # Build automation
├── README.md             # Project documentation
├── .gitignore            # Git ignore rules
├── parts/                # Book content (books only)
│   └── part01/
│       └── part01.tex
├── frontmatter/          # Front matter (books only)
│   ├── preface.tex
│   └── introduction.tex
├── backmatter/           # Back matter (books only)
├── figures/              # Images
├── references/           # Bibliography files
├── configs/              # Custom component overrides
└── .pxis/                # Auto-generated (synced components)
```

Important files:

- workspace.yml: Configuration file - edit this to change components, colors, features
- main.tex: Document entry point - edit this for document structure
- Makefile: Build commands - run make to build
- .pxis/: Auto-generated directory - never edit directly, regenerated on each sync

## Building Your Document

### First Build

```bash
make
```

This:
1. Reads workspace.yml
2. Syncs required components to .pxis/
3. Generates frontmatter (cover, copyright, etc.)
4. Runs LaTeX multiple times
5. Runs bibliography processor if needed
6. Creates build/main.pdf

### Rebuild After Changes

```bash
make
```

Same command. It detects changes and rebuilds.

### Clean Build

Remove all build artifacts:

```bash
make clean
make
```

Use this if build seems broken.

### Watch Mode

Auto-rebuild on file changes:

```bash
make watch
```

Edit your .tex files. Save. Build happens automatically. Great for writing.

Stop with Ctrl+C.

## The Configuration File

workspace.yml is the heart of your project. Example:

```yaml
project:
  type: book
  category: technical
  title: "My Book"
  author: "Your Name"
  email: "you@example.com"
  url: "https://github.com/user/repo"

components:
  - fonts
  - math
  - graphics
  - tables
  - colors
  - layout

colors:
  scheme: technical

overrides:
  components_dir: "configs"
```

See configuration.md for all options.

## Writing Content

### For Books

Add chapters:

```bash
bash workspace/scripts/generator/chapter.sh \
  -p 1 \
  -c 2 \
  -t "Chapter Title"
```

Then include in main.tex or part file:

```latex
\input{parts/part01/chapter02/chapter02}
```

### For Articles

Edit sections directly in main.tex or create separate section files:

```latex
\section{Introduction}

Content here.

\input{sections/methodology}
```

## Adding Images

Place images in figures/ directory:

```latex
\begin{figure}[htbp]
\centering
\includegraphics[width=0.8\textwidth]{figures/diagram.pdf}
\caption{Diagram description}
\label{fig:diagram}
\end{figure}
```

Reference with: `\ref{fig:diagram}`

## Managing Bibliography

Create references/main.bib:

```bibtex
@article{smith2020,
  author = {Smith, John},
  title = {Important Paper},
  journal = {Journal Name},
  year = {2020}
}
```

Cite in text:

```latex
According to \cite{smith2020}, ...
```

Bibliography appears automatically at end.

## Customizing Components

Override any component by placing your version in configs/:

```
configs/
├── colors.tex           # Custom colors
├── commands/
│   └── base.tex        # Custom commands
└── frontmatter/
    └── title.tex       # Custom title page
```

Then tell workspace.yml which overrides to allow:

```yaml
overrides:
  components_dir: "configs"
  allow:
    - colors.tex
    - commands/base.tex
    - frontmatter/title.tex
```

This prevents accidental overrides and makes intentions clear.

## Version Management

Papyrxis uses git tags for versioning:

```bash
# Create a version
git tag v1.0.0
git push --tags

# Build will include version
make
```

Version appears in:
- PDF metadata
- Generated copyright page
- Title page (if configured)

Format is configurable in workspace.yml:

```yaml
version:
  source: git
  format: "v{major}.{minor}.{patch}"
  fallback: "dev"
```

## Common Workflows

### Daily Writing

```bash
make watch
# Edit files, save, see results immediately
```

### Preparing for Release

```bash
make clean
git tag v1.0.0
make
# Creates clean build with version 1.0.0
```

### Sharing with Collaborators

Your collaborators need:
1. Clone your repo with submodules: `git clone --recursive`
2. Install LaTeX
3. Run `make`

No special Papyrxis installation needed if using submodule method.

### Updating Papyrxis

```bash
# Update submodule to latest
cd workspace
git pull origin main
cd ..
git add workspace
git commit -m "Update Papyrxis workspace"

# Resync components
make sync
```

Or use the update script:

```bash
bash workspace/scripts/update.sh
```

## Troubleshooting

### Build Fails with "Command not found"

Missing LaTeX or tools. Install TeX Live:

```bash
# Ubuntu/Debian
sudo apt-get install texlive-full

# macOS
brew install --cask mactex

# Check installation
pdflatex --version
```

### "workspace.yml not found"

You are not in project directory. Navigate to where workspace.yml exists:

```bash
cd /path/to/my-book
make
```

### Components Not Found

Run sync explicitly:

```bash
make sync
```

If still failing, check workspace.yml has correct component names. See configuration.md for valid components.

### Permission Denied on Scripts

Make scripts executable:

```bash
chmod +x workspace/scripts/*.sh
```

### Build Works But PDF Looks Wrong

Check which preset you are using. For books:

```latex
% In main.tex
\input{.pxis/preset}
```

For articles, ensure you are inputting the correct preset from common/presets/article/.

### Git Submodule Issues

If submodule is empty:

```bash
git submodule update --init --recursive
```

If submodule is outdated:

```bash
git submodule update --remote
```

## Next Steps

Now that you have a working setup:

1. Read configuration.md to understand all options
2. Read customization.md to learn about overrides and custom components
3. Read templates.md to understand the template system
4. Start writing content

For questions and discussions, visit the repository issues or discussions page.

## Summary

Core concepts:
- workspace.yml configures everything
- make builds your document
- Components sync to .pxis/ automatically
- Override components in configs/
- Git tags create versions

Most common commands:
- `make` - build document
- `make watch` - auto-rebuild
- `make clean` - clean build artifacts
- `make sync` - regenerate .pxis/

Everything else is standard LaTeX.