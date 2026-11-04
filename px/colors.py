"""Compatibility terminal formatting; all log records use m-mdy-m/log.c."""

from __future__ import annotations

from .logger import log as _log

RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
BLUE = "\033[0;34m"
CYAN = "\033[0;36m"
MAGENTA = "\033[0;35m"
GREY = "\033[0;37m"


def log(msg: str) -> None:
    _log("info", msg, component="compat")


def success(msg: str) -> None:
    _log("info", msg, component="compat", status="ok")


def warn(msg: str) -> None:
    _log("warn", msg, component="compat", status="warning")


def info(msg: str) -> None:
    _log("info", msg, component="compat")


def dim(msg: str) -> None:
    _log("debug", msg, component="compat")


def error(msg: str, exit_code: int = 1) -> None:
    _log("error", msg, component="compat", status="failed")
    raise SystemExit(exit_code)


def b(text: str) -> str:
    return f"{BOLD}{text}{RESET}"


def c(text: str) -> str:
    return f"{CYAN}{text}{RESET}"
