# Single-article example (schema v1)

This fixture demonstrates the original one-document configuration and its unchanged output layout.

~~~sh
px --root . list
px --root . build
px --root . verify
px --root . clean
~~~

The source uses the shared `article/ieee.tex` preset. The project root, `tex/` and `configs/` directories take precedence over the installed Workspace presets, so a project can override any shared component without forking the toolchain.
