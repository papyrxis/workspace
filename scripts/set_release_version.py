#!/usr/bin/env python3
"""Synchronize package metadata with Pipeline's validated release tag."""
from __future__ import annotations

import os
import re
from pathlib import Path

TAG = re.compile(r"^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-(alpha|beta|rc)\.([1-9][0-9]*))?$")


def pep440_version(tag: str) -> str:
    match = TAG.fullmatch(tag)
    if not match:
        raise ValueError(f"unsupported SemVer release tag: {tag!r}")
    major, minor, patch, stage, number = match.groups()
    base = f"{major}.{minor}.{patch}"
    if stage is None:
        return base
    suffix = {"alpha": "a", "beta": "b", "rc": "rc"}[stage]
    return f"{base}{suffix}{number}"


def main() -> int:
    tag = os.environ.get("PIPELINE_RELEASE_TAG", "").strip()
    if not tag:
        raise SystemExit("PIPELINE_RELEASE_TAG is required; this script must run inside Pipeline release preparation")
    version = pep440_version(tag)
    root = Path(__file__).resolve().parents[1]
    pyproject = root / "pyproject.toml"
    content = pyproject.read_text(encoding="utf-8")
    updated, count = re.subn(r'(?m)^version\s*=\s*"[^"]+"$', f'version = "{version}"', content, count=1)
    if count != 1:
        raise SystemExit("could not locate [project].version in pyproject.toml")
    pyproject.write_text(updated, encoding="utf-8")
    init_file = root / "px" / "__init__.py"
    init_content = init_file.read_text(encoding="utf-8")
    init_updated, init_count = re.subn(r'(?m)^__version__\s*=\s*"[^"]+"$', f'__version__ = "{version}"', init_content, count=1)
    if init_count != 1:
        raise SystemExit("could not locate px.__version__")
    init_file.write_text(init_updated, encoding="utf-8")
    print(f"Prepared package version {version} from release tag {tag}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
