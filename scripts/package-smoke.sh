#!/usr/bin/env bash
set -euo pipefail

temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT
distribution="$temporary/dist"
mkdir -p "$distribution"

python -m pip install --upgrade build twine
python -m build --sdist --wheel --outdir "$distribution"
python -m twine check "$distribution"/*.whl "$distribution"/*.tar.gz
python scripts/package_release.py --input "$distribution" --output "$distribution/papyrxis-workspace-release.zip"
python scripts/test_release_install.py --bundle "$distribution/papyrxis-workspace-release.zip"

echo "Wheel, sdist, shared TeX resources and installed CLI package smoke test passed."
