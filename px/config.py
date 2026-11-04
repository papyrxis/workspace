"""Safe YAML configuration, validation and precedence for Workspace projects."""
from __future__ import annotations

from copy import deepcopy
from pathlib import Path
from typing import Any, Mapping

import yaml

ENGINES = {"pdflatex", "xelatex", "lualatex"}
PROJECT_TYPES = {"book", "booklet", "article", "cv"}

DEFAULTS: dict[str, Any] = {
    "schema_version": 1,
    "project": {
        "name": "document",
        "type": "book",
        "title": "Untitled document",
        "author": "",
        "languages": ["en"],
    },
    "build": {
        "output_dir": "build",
        "default_engine": "xelatex",
        "timeout_seconds": 1800,
        "entries": {"en": {"source": "main.tex", "engine": "xelatex"}},
    },
    "export": {"output_dir": "build/export", "targets": ["devto"], "tag_limit": 5},
    "targets": {},
}


class ConfigError(ValueError):
    """A project configuration is malformed or unsafe."""


def deep_merge(base: Mapping[str, Any], override: Mapping[str, Any]) -> dict[str, Any]:
    """Recursively merge mappings; scalar values and lists in the override win."""
    result = deepcopy(dict(base))
    for key, value in override.items():
        if isinstance(value, Mapping) and isinstance(result.get(key), Mapping):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = deepcopy(value)
    return result


def _safe_relative(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ConfigError(f"{label} must be a non-empty relative path")
    path = Path(value)
    if path.is_absolute() or ".." in path.parts:
        raise ConfigError(f"{label} must stay inside the project directory")
    return value


def validate_config(config: Mapping[str, Any]) -> None:
    if config.get("schema_version") != 1:
        raise ConfigError("schema_version must be 1")
    project = config.get("project")
    build = config.get("build")
    export = config.get("export")
    if not isinstance(project, Mapping) or not isinstance(build, Mapping) or not isinstance(export, Mapping):
        raise ConfigError("project, build and export must be YAML mappings")
    if project.get("type") not in PROJECT_TYPES:
        raise ConfigError(f"project.type must be one of: {', '.join(sorted(PROJECT_TYPES))}")
    languages = project.get("languages")
    if not isinstance(languages, list) or not languages or not all(isinstance(x, str) and x for x in languages):
        raise ConfigError("project.languages must be a non-empty list of language codes")
    _safe_relative(build.get("output_dir", "build"), "build.output_dir")
    engine = build.get("default_engine", "xelatex")
    if engine not in ENGINES:
        raise ConfigError(f"build.default_engine must be one of: {', '.join(sorted(ENGINES))}")
    entries = build.get("entries")
    if not isinstance(entries, Mapping) or not entries:
        raise ConfigError("build.entries must map language codes to source definitions")
    for language, entry in entries.items():
        if language not in languages:
            raise ConfigError(f"build.entries contains {language!r}, which is not listed in project.languages")
        if isinstance(entry, str):
            source, selected_engine = entry, engine
        elif isinstance(entry, Mapping):
            source, selected_engine = entry.get("source"), entry.get("engine", engine)
        else:
            raise ConfigError(f"build.entries.{language} must be a source string or mapping")
        _safe_relative(source, f"build.entries.{language}.source")
        if selected_engine not in ENGINES:
            raise ConfigError(f"build.entries.{language}.engine must be one of: {', '.join(sorted(ENGINES))}")
    _safe_relative(export.get("output_dir", "build/export"), "export.output_dir")
    targets = export.get("targets", [])
    if not isinstance(targets, list) or not all(isinstance(x, str) and x for x in targets):
        raise ConfigError("export.targets must be a list of target names")
    tag_limit = export.get("tag_limit", 5)
    if type(tag_limit) is not int or not 1 <= tag_limit <= 20:
        raise ConfigError("export.tag_limit must be an integer between 1 and 20")
    if not isinstance(config.get("targets", {}), Mapping):
        raise ConfigError("targets must be a YAML mapping")


def load_config(
    root: str | Path = ".",
    config_path: str | Path | None = None,
    overrides: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    """Load built-ins, then project YAML, then explicit CLI overrides."""
    base = Path(root).expanduser().resolve()
    path = Path(config_path or "workspace.yml").expanduser()
    path = path if path.is_absolute() else base / path
    raw: dict[str, Any] = {}
    if path.is_file():
        try:
            loaded = yaml.safe_load(path.read_text(encoding="utf-8"))
        except (OSError, yaml.YAMLError) as exc:
            raise ConfigError(f"cannot read {path}: {exc}") from exc
        if loaded is not None and not isinstance(loaded, dict):
            raise ConfigError(f"{path} must contain a YAML mapping")
        raw = loaded or {}
    elif config_path is not None:
        raise ConfigError(f"configuration file not found: {path}")
    merged = deep_merge(DEFAULTS, raw)
    if overrides:
        merged = deep_merge(merged, overrides)
    validate_config(merged)
    return merged
