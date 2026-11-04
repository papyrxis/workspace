"""Shared subprocess boundaries with legacy and strict APIs."""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path
from typing import Mapping, Sequence


class CommandError(RuntimeError):
    def __init__(self, command: Sequence[str], code: int, stderr: str = "") -> None:
        self.command = tuple(command)
        self.code = code
        self.stderr = stderr
        super().__init__(f"command failed with exit code {code}: {' '.join(command)}" + (f"\n{stderr.strip()}" if stderr.strip() else ""))


def _environment(env: Mapping[str, str] | None) -> dict[str, str]:
    result = os.environ.copy()
    if env:
        result.update(env)
    return result


def run(
    cmd: Sequence[str],
    cwd: str | Path | None = None,
    capture: bool = False,
    env: Mapping[str, str] | None = None,
) -> subprocess.CompletedProcess:
    """Legacy API: retain byte output and exit-on-failure behavior for old scripts."""
    result = subprocess.run(
        list(cmd), cwd=cwd, env=_environment(env),
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
        check=False,
    )
    if result.returncode != 0 and not capture:
        raise SystemExit(result.returncode)
    return result


def run_quiet(
    cmd: Sequence[str],
    cwd: str | Path | None = None,
    env: Mapping[str, str] | None = None,
) -> tuple[int, str, str]:
    """Legacy silent API returning (returncode, stdout, stderr) without exiting."""
    result = subprocess.run(
        list(cmd), cwd=cwd, env=_environment(env),
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, check=False,
    )
    return result.returncode, result.stdout, result.stderr


def run_checked(
    command: Sequence[str],
    *,
    cwd: str | Path,
    env: Mapping[str, str] | None = None,
    timeout: int | None = None,
) -> subprocess.CompletedProcess[str]:
    """Strict API for new workspace code: text output and typed failures."""
    if not command or not all(isinstance(item, str) for item in command):
        raise ValueError("command must be a non-empty sequence of strings")
    try:
        result = subprocess.run(
            list(command), cwd=Path(cwd), env=_environment(env),
            text=True, capture_output=True, check=False, timeout=timeout,
        )
    except FileNotFoundError as exc:
        raise CommandError(command, 127, str(exc)) from exc
    except subprocess.TimeoutExpired as exc:
        raise CommandError(command, 124, f"timed out after {timeout} seconds") from exc
    if result.returncode:
        raise CommandError(command, result.returncode, result.stderr)
    return result
