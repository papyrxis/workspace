# Getting Started

## Install

As a git submodule (recommended — keeps workspace separate from your content):

```bash
mkdir my-project && cd my-project
git init
git submodule add https://github.com/papyrxis/workspace.git
bash workspace/src/init.sh
```

Direct clone (simpler if you have one project):

```bash
git clone https://github.com/papyrxis/workspace.git my-project
cd my-project
bash src/init.sh
```

The init script asks a few questions and creates:
- `workspace.yml` — your configuration
- `main.tex` — document entry point
- `Makefile` — build automation
- Directory structure appropriate for your project type

## First build

```bash
make sync   # generate .pxis/ from workspace.yml
make        # compile the PDF
```

Output: `build/main.pdf` (or whatever `build.source` points to).

## Day to day

```bash
make watch  # auto-rebuild on save, Ctrl+C to stop
```

When you edit `workspace.yml`:

```bash
make sync   # re-generate .pxis/
make        # rebuild
```

When you update the workspace submodule:

```bash
cd workspace && git pull && cd ..
make sync
```

## Prerequisites

```bash
pdflatex --version   # TeX Live or MiKTeX
biber --version
git --version
make --version
python3 -c "import yaml; print('ok')"   # PyYAML
```

Install TeX Live on Ubuntu/Debian:

```bash
sudo apt-get install texlive-full
```

On macOS:

```bash
brew install --cask mactex
```
