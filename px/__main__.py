"""
CLI entry point for the shared px engine — lets bash (Makefiles, other
shell scripts) call into the one canonical implementation instead of
re-deriving the LaTeX-artifact cleanup list or the version string locally.

    python3 -m px clean [path]     Remove LaTeX build artifacts under `path` (default: .)
    python3 -m px version [path]   Print `git describe` version for the repo at `path` (default: .)

Requires `workspace/` (this package's parent directory) to be on
PYTHONPATH — e.g. from a Makefile:

    PYTHONPATH="$(WORKSPACE_PY)" python3 -m px clean .

Exits non-zero on usage errors, and lets ImportError/FileNotFoundError
propagate as a non-zero exit too, so a Makefile `||` fallback can still
catch the case where Python 3 (or this package) isn't reachable at all —
same "prefer Python, degrade to bash" philosophy already used by
src/parser.sh for YAML parsing.
"""

from __future__ import annotations

import sys
from pathlib import Path

from .colors import success, warn
from .latex import clean_latex_artifacts, git_describe


def _cmd_clean(args: list[str]) -> int:
    target = Path(args[0]) if args else Path(".")
    if not target.exists():
        warn(f"path not found: {target}")
        return 1
    removed = clean_latex_artifacts(target)
    success(f"removed {removed} LaTeX artifact file(s) under {target}")
    return 0


def _cmd_version(args: list[str]) -> int:
    target = Path(args[0]) if args else Path(".")
    print(git_describe(target))
    return 0


COMMANDS = {
    "clean": _cmd_clean,
    "version": _cmd_version,
}


def main() -> int:
    args = sys.argv[1:]
    if not args or args[0] not in COMMANDS:
        print(f"usage: python3 -m px {{{'|'.join(COMMANDS)}}} [path]", file=sys.stderr)
        return 2
    return COMMANDS[args[0]](args[1:])


if __name__ == "__main__":
    sys.exit(main())
