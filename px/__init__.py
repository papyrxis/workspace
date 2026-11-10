"""Public compatibility API for the Papyrxis Workspace package."""

__version__ = "0.3.0"

from .base_module import BaseModule
from .colors import BLUE, BOLD, CYAN, DIM, GREEN, GREY, MAGENTA, RED, RESET, YELLOW, b, c, dim, error, info, log, success, warn
from .conf import list_conf_files, load_conf, resolve_by_index
from .interactive import choose_from_list, confirm, confirm_slug, prompt
from .latex import LATEX_ARTIFACTS, clean_latex_artifacts, git_describe
from .process import run, run_quiet
from .ui import col, hr
from .watch import dir_checksum, watch_loop

__all__ = [
    "BaseModule", "BLUE", "BOLD", "CYAN", "DIM", "GREEN", "GREY", "MAGENTA", "RED", "RESET", "YELLOW",
    "b", "c", "dim", "error", "info", "log", "success", "warn", "list_conf_files", "load_conf",
    "resolve_by_index", "choose_from_list", "confirm", "confirm_slug", "prompt", "LATEX_ARTIFACTS",
    "clean_latex_artifacts", "git_describe", "run", "run_quiet", "col", "hr", "dir_checksum", "watch_loop",
]
