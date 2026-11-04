"""Built-in Markdown export profiles; CSL and filters are opt-in."""
from __future__ import annotations

from typing import Any

BUILTIN_TARGETS: dict[str, dict[str, Any]] = {
    "devto": {"label": "dev.to", "format": "gfm", "front_matter": True, "csl": None, "filters": [], "max_tags": 5},
    "medium": {"label": "Medium", "format": "gfm", "front_matter": False, "csl": None, "filters": []},
    "ieee": {"label": "IEEE", "format": "markdown", "front_matter": False, "csl": "common/csl/ieee.csl", "filters": []},
    "journal": {"label": "Journal manuscript", "format": "markdown", "front_matter": False, "csl": None, "filters": []},
}


def resolve_target(name: str, overrides: dict[str, Any] | None = None) -> dict[str, Any]:
    target = dict(BUILTIN_TARGETS.get(name, {}))
    custom = (overrides or {}).get(name, {})
    if not target and not custom:
        raise KeyError(f"unknown export target {name!r}")
    if not isinstance(custom, dict):
        raise ValueError(f"target override {name!r} must be a mapping")
    target.update(custom)
    if not target.get("format"):
        raise KeyError(f"target {name!r} has no output format")
    if target.get("csl") is not None and not isinstance(target["csl"], str):
        raise ValueError(f"target {name!r} csl must be a path or null")
    if not isinstance(target.get("filters", []), list):
        raise ValueError(f"target {name!r} filters must be a list")
    return target
