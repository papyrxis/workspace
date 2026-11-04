"""Generate categorized release notes from Conventional Commit subjects."""
from __future__ import annotations

import re
from pathlib import Path

from .process import run_checked

_GROUPS = {
    "feat": "Added", "fix": "Fixed", "perf": "Performance", "docs": "Documentation",
    "refactor": "Changed", "build": "Build", "ci": "CI", "test": "Tests", "chore": "Maintenance",
}
_PATTERN = re.compile(r"^(?P<type>[a-z]+)(?:\([^)]+\))?(?P<breaking>!)?:\s*(?P<subject>.+)$")


def generate_changelog(root: str | Path, output: str = "CHANGELOG.md", version: str = "Unreleased", dry_run: bool = False) -> str:
    base = Path(root).resolve()
    result = run_checked(["git", "log", "--no-merges", "--format=%s", "-100"], cwd=base)
    groups: dict[str, list[str]] = {}
    for subject in result.stdout.splitlines():
        match = _PATTERN.match(subject.strip())
        if not match:
            continue
        category = _GROUPS.get(match.group("type"))
        if category:
            title = match.group("subject").strip()
            if match.group("breaking"):
                title += " (breaking)"
            groups.setdefault(category, []).append(title)
    order = ["Added", "Fixed", "Changed", "Performance", "Documentation", "Build", "CI", "Tests", "Maintenance"]
    lines = [f"## {version}", ""]
    for category in order:
        items = groups.get(category, [])
        if items:
            lines.extend([f"### {category}", ""])
            lines.extend(f"- {item}" for item in items)
            lines.append("")
    if len(lines) == 2:
        lines.extend(["No Conventional Commit entries found.", ""])
    generated = "\n".join(lines).rstrip() + "\n"
    path = Path(output)
    if path.is_absolute() or ".." in path.parts:
        raise ValueError("changelog output must stay inside the project")
    target = base / path
    existing = target.read_text(encoding="utf-8") if target.is_file() else "# Changelog\n"
    if not dry_run:
        target.parent.mkdir(parents=True, exist_ok=True)
        if existing.startswith("# Changelog"):
            heading, _, body = existing.partition("\n")
            updated = heading + "\n\n" + generated + body.lstrip("\n")
        else:
            updated = generated + "\n" + existing
        target.write_text(updated, encoding="utf-8")
    return generated
