# Multi-document example

This fixture contains one article, one bilingual booklet, and three independently configured book volumes.

Run from this directory:

~~~sh
python -m pip install -e ../../
px --root . list
px --root . build
px --root . build bilingual-handbook --edition fa
px --root . verify
px --root . clean arliz-volume-2
~~~

The default output layout is `build/<document-id>/<edition>/<output-name>.pdf`. The build manifest is `build/manifest.json`; every successful record includes the source, engine, output, byte size and SHA-256.

The Persian example uses the `Amiri` font. Install it (and the required XeLaTeX/xepersian packages) before building the Persian edition. The other examples use pdfLaTeX.
