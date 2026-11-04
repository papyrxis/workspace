"""Safe subprocess helpers; commands are argument arrays, never implicit shell text."""
from __future__ import annotations

import os
import subprocess
from pathlib import Path
from typing import Mapping, Sequence


class CommandError(RuntimeError):
    def __init__(self, command: Sequence[str], code: int, stderr: str = "") -> None:
        self.command = tuple(command)
        self.code = code
        self.stderr = stderr
        super().__init__(f"command failed with exit code {code}: {' '.join(command)}" + (f"\n{stderr.strip()}" if stderr.strip() else ""))


def run(
    command: Sequence[str],
    *,
    cwd: str | Path,
    env: Mapping[str, str] | None = None,
    capture: bool = False,
    timeout: int | None = None,
) -> subprocess.CompletedProcess[str]:
    if not command or not all(isinstance(item, str) for item in command):
        raise ValueError("command must be a non-empty sequence of strings")
    full_env = os.environ.copy()
    if env:
        full_env.update(env)
    try:
        result = subprocess.run(
            list(command), cwd=Path(cwd), env=full_env, text=True,
            capture_output=capture, check=False, timeout=timeout,
        )
    except FileNotFoundError as exc:
        raise CommandError(command, 127, str(exc)) from exc
    except subprocess.TimeoutExpired as exc:
        raise CommandError(command, 124, f"timed out after {timeout} seconds") from exc
    if result.returncode:
        raise CommandError(command, result.returncode, result.stderr if capture else "")
    return result
