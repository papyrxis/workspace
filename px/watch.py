"""
File-system watch utilities — shared by the collection CLIs (papers,
resumes, roadmaps, booklets, ...) and, going forward, available to the
bash single-document layer too.

Consolidates what used to be two separate implementations:

  - workspace/src/build.sh's watch_mode(): inotifywait -> fswatch -> poll,
    OS-native and efficient, but rebuilds on *any* filesystem event in the
    watched tree (no precise "did a .tex/.bib actually change" check).

  - papers/scripts/common/watch.py (this file's previous version): a pure
    Python polling loop, portable everywhere, and precise (only rebuilds
    when a file matching `patterns` actually changed — via mtime+size
    fingerprint) but always polls, even when a native OS backend is sitting
    right there unused.

This version keeps both ideas: when `inotifywait` or `fswatch` is on PATH,
they're used purely as an efficient "something changed, go look" wakeup —
the actual rebuild decision still runs through the same dir_checksum()
fingerprint used by the polling path, so a stray .aux write or editor swap
file won't trigger a rebuild just because the OS watcher saw it. No native
backend available -> falls straight back to the polling loop, unchanged.

dir_checksum(paths, patterns)
    Compute a lightweight fingerprint of the files matching `patterns`
    under the given paths (mtime + size, no hashing). Returns a frozenset
    of (path_str, mtime_ns, size) tuples.

watch_loop(watch_paths, patterns, rebuild_fn, interval)
    Watch for changes and call `rebuild_fn()` whenever the fingerprint
    changes. Picks the best available backend automatically. Runs until
    Ctrl-C.
"""

from __future__ import annotations

import shutil
import subprocess
import time
from pathlib import Path
from typing import Callable

from .colors import DIM, GREEN, RESET, warn

# Directories/patterns an OS-native watcher should ignore outright —
# mirrors build.sh's `--exclude '\.git|build/|\.swp|\.aux|\.log'`.
_NATIVE_EXCLUDE_REGEX = r"\.git|/build/|\.swp$|\.aux$|\.log$|\.synctex\.gz$"


# ── fingerprint ───────────────────────────────────────────────────────────────

def dir_checksum(
    paths: list[Path],
    patterns: list[str],
) -> frozenset[tuple[str, int, int]]:
    """
    Return a frozenset of (absolute_path, mtime_ns, size) for every file
    under `paths` that matches at least one glob in `patterns`.

    Works on both individual files and directories:
    - if a path is a file, it is checked directly against the patterns
      (by name) and included if it matches.
    - if a path is a directory, it is searched recursively with rglob.
    """
    entries: set[tuple[str, int, int]] = set()
    for base in paths:
        base = Path(base)
        if not base.exists():
            continue
        if base.is_file():
            if any(base.match(pat) for pat in patterns):
                try:
                    st = base.stat()
                    entries.add((str(base), st.st_mtime_ns, st.st_size))
                except OSError:
                    pass
        else:
            for pat in patterns:
                for fpath in base.rglob(pat):
                    if fpath.is_file():
                        try:
                            st = fpath.stat()
                            entries.add((str(fpath), st.st_mtime_ns, st.st_size))
                        except OSError:
                            pass
    return frozenset(entries)


def _diff_and_report(last: frozenset, current: frozenset) -> bool:
    """Print what changed; return True if `current` actually differs from `last`."""
    if current == last:
        return False
    changed = {p for p, *_ in current} ^ {p for p, *_ in last}
    if not changed:
        changed = {p for p, m, s in current if (p, m, s) not in last}
    for p in sorted(changed):
        print(f"  {GREEN}changed{RESET}  {DIM}{p}{RESET}")
    print()
    return True


# ── backend selection ────────────────────────────────────────────────────────

def _pick_backend() -> str:
    """Mirror src/checker.sh:check_watch_tool() — prefer OS-native, fall back to polling."""
    if shutil.which("inotifywait"):
        return "inotifywait"
    if shutil.which("fswatch"):
        return "fswatch"
    return "poll"


# ── public loop ───────────────────────────────────────────────────────────────

def watch_loop(
    watch_paths: list[Path],
    patterns: list[str],
    rebuild_fn: Callable[[], None],
    interval: float = 1.0,
) -> None:
    """
    Watch `watch_paths` for changes matching `patterns` and call
    `rebuild_fn()` whenever the fingerprint changes. Picks the fastest
    backend available (inotifywait > fswatch > polling) transparently.
    Exits cleanly on KeyboardInterrupt (Ctrl-C).
    """
    backend = _pick_backend()
    last = dir_checksum(watch_paths, patterns)

    if backend == "poll":
        warn("inotifywait/fswatch not found — falling back to polling (install either for faster, lower-CPU watching)")
    print(f"\n  {DIM}Watching for changes ({backend}) — Ctrl-C to stop{RESET}\n")

    try:
        if backend == "inotifywait":
            _run_native_loop(
                ["inotifywait", "-q", "-e", "modify,create,delete,move",
                 "--exclude", _NATIVE_EXCLUDE_REGEX, "-r", *[str(p) for p in watch_paths]],
                watch_paths, patterns, rebuild_fn, last,
            )
        elif backend == "fswatch":
            _run_native_loop(
                ["fswatch", "-o", "-e", _NATIVE_EXCLUDE_REGEX,
                 *[str(p) for p in watch_paths]],
                watch_paths, patterns, rebuild_fn, last,
            )
        else:
            _watch_loop_poll(watch_paths, patterns, rebuild_fn, last, interval)
    except KeyboardInterrupt:
        print(f"\n  {DIM}Watch stopped.{RESET}\n")
    except FileNotFoundError:
        # backend binary vanished between the which() check and exec (rare) — degrade gracefully
        warn(f"{backend} became unavailable — switching to polling")
        _watch_loop_poll(watch_paths, patterns, rebuild_fn, last, interval)


def _run_native_loop(cmd, watch_paths, patterns, rebuild_fn, last):
    """Block on a native watcher process; each line/exit is just a wakeup — the
    real "did anything we care about change" check still goes through dir_checksum."""
    while True:
        proc = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        # inotifywait exits once per event batch; fswatch -o prints and keeps running,
        # but subprocess.run() blocking here still re-checks on every wakeup either way.
        current = dir_checksum(watch_paths, patterns)
        if _diff_and_report(last, current):
            try:
                rebuild_fn()
            except Exception as exc:  # noqa: BLE001
                warn(f"rebuild failed: {exc}")
            last = current
        else:
            last = current
        if proc.returncode not in (0, 1):
            # unexpected failure (e.g. binary missing mid-run) — bail to polling
            raise FileNotFoundError(cmd[0])


def _watch_loop_poll(watch_paths, patterns, rebuild_fn, last, interval: float) -> None:
    while True:
        time.sleep(interval)
        current = dir_checksum(watch_paths, patterns)
        if _diff_and_report(last, current):
            try:
                rebuild_fn()
            except Exception as exc:  # noqa: BLE001
                warn(f"rebuild failed: {exc}")
            last = current
