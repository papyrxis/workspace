"""
px — shared engine for Papyrxis projects.

Originally scripts/common/ inside the `papers` repo; promoted into the
`workspace` submodule so every consumer (papers, arliz, mathesis, and
whatever comes next) shares one implementation instead of N copies.

All public symbols are re-exported here so existing imports of the form
    from common import foo, bar
keep working unchanged after switching the import path to
    from px import foo, bar
(or, if `workspace` is on sys.path as a package, `from workspace.px import ...`).

Layout:
  base_module.py   BaseModule ABC — banner, interactive menu, help, main()
  colors.py        ANSI color constants + terminal logging helpers
  conf.py          bash-style .conf parser + index/slug resolver
  interactive.py   prompt / confirm / confirm_slug / choose_from_list
  process.py       subprocess wrappers (run / run_quiet)
  latex.py         LaTeX artifact cleanup patterns + git-describe versioning
  watch.py         file-watch loop — OS-native backend when available,
                    polling fallback otherwise (mirrors src/build.sh's
                    inotifywait -> fswatch -> poll chain, in Python)
  ui.py            hr() / col() terminal formatting helpers
"""

from .base_module import BaseModule
from .colors import (
    BLUE, BOLD, CYAN, DIM, GREEN, GREY, MAGENTA, RED, RESET, YELLOW,
    b, c, dim, error, info, log, success, warn,
)
from .conf import list_conf_files, load_conf, resolve_by_index
from .interactive import choose_from_list, confirm, confirm_slug, prompt
from .latex import LATEX_ARTIFACTS, clean_latex_artifacts, git_describe
from .process import run, run_quiet
from .ui import col, hr
from .watch import dir_checksum, watch_loop

__all__ = [
    # base
    "BaseModule",
    # colors / logging
    "BLUE", "BOLD", "CYAN", "DIM", "GREEN", "GREY", "MAGENTA",
    "RED", "RESET", "YELLOW",
    "b", "c", "dim", "error", "info", "log", "success", "warn",
    # conf
    "list_conf_files", "load_conf", "resolve_by_index",
    # interactive
    "choose_from_list", "confirm", "confirm_slug", "prompt",
    # latex
    "LATEX_ARTIFACTS", "clean_latex_artifacts", "git_describe",
    # process
    "run", "run_quiet",
    # ui
    "col", "hr",
    # watch
    "dir_checksum", "watch_loop",
]
