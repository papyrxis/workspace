# Getting started

## Requirements

- Python 3.10+ and PyYAML.
- TeX Live or MiKTeX with latexmk and the engines selected by the project.
- Pandoc only for Markdown export.
- The m-mdy-m/log.c shared library for native structured logging.
- gix and psx for repository flow and quality checks.

Install Workspace from a checkout:

~~~sh
python -m pip install -e .
~~~

When using Workspace as a submodule, install the package from that folder or add it to PYTHONPATH:

~~~sh
git submodule add https://github.com/papyrxis/workspace.git workspace
python -m pip install -e workspace
~~~

## Install the shared logger

Workspace calls the stable C ABI from m-mdy-m/log.c. Build a pinned version:

~~~sh
git clone --branch v0.1.0 --depth 1 https://github.com/m-mdy-m/log.c.git /tmp/mmlog
cmake -S /tmp/mmlog -B /tmp/mmlog/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local" -DBUILD_SHARED_LIBS=ON
cmake --build /tmp/mmlog/build
cmake --install /tmp/mmlog/build
~~~

If the dynamic loader cannot find the shared object, set M_MDY_M_LOG_LIBRARY to its full path. The initial CLI bootstrap still has a stderr fallback; px doctor tells you whether the native logger is active.

## Create a book

~~~sh
mkdir my-book && cd my-book
px init --type book --language en
~~~

For an English and Persian book:

~~~sh
px init --type book --language both
~~~

The generator creates workspace.yml, a small Makefile, a main.tex for each language, and conventional chapters or sections, frontmatter, backmatter, figures and references directories. It does not overwrite existing source files unless --force is explicit.

## Build

~~~sh
px build
px build --language en
px build --language fa
make clean
~~~

Each configured language is built with its own LaTeX engine. PDFs are written under build/<language>/ and validated before success is reported.

## Export an article

Install Pandoc with your operating system's package manager, then run:

~~~sh
px export --target devto
px export --target medium
px tags
~~~

CSL is opt-in. Most publishing targets do not need an extra CSL file. The IEEE target uses the shared IEEE CSL profile.

## Repository checks and releases

~~~sh
psx check --config psx.yml
pipeline run check
gix doctor
gix feature start improve-template
px changelog
gix version bump patch
px push --tags
~~~

Read Configuration, Architecture, Build and export, and Release workflow before customizing advanced behavior.
