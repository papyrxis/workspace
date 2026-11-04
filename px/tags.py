"""Stable, platform-safe tag generation."""
from __future__ import annotations

import re
import unicodedata
from typing import Iterable


def _tag(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii").lower()
    normalized = re.sub(r"[^a-z0-9]+", "-", normalized).strip("-")
    return normalized[:20].rstrip("-")


def generate_tags(values: Iterable[str], limit: int = 5) -> list[str]:
    if limit < 1:
        raise ValueError("limit must be positive")
    output: list[str] = []
    seen: set[str] = set()
    for value in values:
        candidate = _tag(str(value))
        if candidate and candidate not in seen:
            seen.add(candidate)
            output.append(candidate)
        if len(output) >= limit:
            break
    return output
