# Build and export

## Build editions

~~~sh
px build
px build --language en
px build --language fa
make build-en
make build-fa
~~~

Each build entry chooses its own engine. An English pdfLaTeX manuscript and a Persian XeLaTeX edition can share one project configuration without sharing engine assumptions.

Workspace invokes latexmk with non-interactive, halt-on-error and file/line reporting flags. Compiler failures remain failures. A PDF must also pass artifact validation before the build is reported as successful.

## Export Markdown

~~~sh
px export --target devto
px export --target medium
px export --target ieee
~~~

Pandoc converts LaTeX to Markdown. The chosen target controls front matter, filters and citation style.

## CSL policy

- A target with no csl key does not run pandoc citeproc.
- A target with csl set must point to an existing CSL file.
- Reuse common CSL files rather than copying identical versions into every document.
- Keep project-specific export behavior in workspace.yml or a local Pandoc filter.

The default dev.to target does not need an IEEE CSL file. IEEE citations are enabled only by the IEEE profile.
