"""Safe YAML configuration, validation and precedence for Workspace projects."""
from __future__ import annotations

from copy import deepcopy
from pathlib import Path, PureWindowsPath
import re
from typing import Any, Mapping

import yaml

ENGINES = {"pdflatex", "xelatex", "lualatex"}
PROJECT_TYPES = {"book", "booklet", "article", "cv", "collection"}
ARTICLE_STYLES = {"personal", "academic", "ieee", "technical"}
_TARGET_NAME = re.compile(r"^[a-z0-9][a-z0-9_-]*$")
_LANGUAGE_CODE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_-]*$")

DEFAULTS: dict[str, Any] = {
    "schema_version": 1,
    "project": {"name": "document", "type": "book", "title": "Untitled document",
                "author": "", "languages": ["en"]},
    "build": {"output_dir": "build", "default_engine": "xelatex", "timeout_seconds": 1800,
              "entries": {"en": {"source": "main.tex", "engine": "xelatex"}}},
    "export": {"output_dir": "build/export", "targets": ["devto"], "tag_limit": 5},
    "targets": {},
}


class ConfigError(ValueError):
    """A project configuration is malformed or unsafe."""


def deep_merge(base: Mapping[str, Any], override: Mapping[str, Any]) -> dict[str, Any]:
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
    windows_path = PureWindowsPath(value)
    if path.is_absolute() or windows_path.is_absolute() or windows_path.drive or ".." in path.parts or ".." in windows_path.parts:
        raise ConfigError(f"{label} must stay inside the project directory")
    return value


def _validate_edition(edition: Any, label: str, default_engine: str) -> None:
    if not isinstance(edition, Mapping):
        raise ConfigError(f"{label} must be a mapping")
    _safe_relative(edition.get("source"), f"{label}.source")
    engine = edition.get("engine", default_engine)
    if engine not in ENGINES:
        raise ConfigError(f"{label}.engine must be one of: {', '.join(sorted(ENGINES))}")
    output_name = edition.get("output_name")
    if output_name is not None and (not isinstance(output_name, str) or not _LANGUAGE_CODE.fullmatch(output_name)):
        raise ConfigError(f"{label}.output_name must be a safe filename stem")


def validate_config(config: Mapping[str, Any]) -> None:
    version = config.get("schema_version")
    if version not in (1, 2):
        raise ConfigError("schema_version must be 1 or 2")
    project, build, export = config.get("project"), config.get("build"), config.get("export")
    if not all(isinstance(value, Mapping) for value in (project, build, export)):
        raise ConfigError("project, build and export must be YAML mappings")
    allowed_project_types = PROJECT_TYPES if version == 2 else PROJECT_TYPES - {"collection"}
    if not isinstance(project.get("type"), str) or project.get("type") not in allowed_project_types:
        raise ConfigError(f"project.type must be one of: {', '.join(sorted(PROJECT_TYPES))}")
    languages = project.get("languages")
    if not isinstance(languages, list) or not languages or not all(
        isinstance(x, str) and _LANGUAGE_CODE.fullmatch(x) for x in languages
    ):
        raise ConfigError("project.languages must be a non-empty list of safe language identifiers")
    _safe_relative(build.get("output_dir", "build"), "build.output_dir")
    engine = build.get("default_engine", "xelatex")
    if engine not in ENGINES:
        raise ConfigError(f"build.default_engine must be one of: {', '.join(sorted(ENGINES))}")
    timeout = build.get("timeout_seconds", 1800)
    if type(timeout) is not int or timeout < 1:
        raise ConfigError("build.timeout_seconds must be a positive integer")

    project_style = project.get("style")
    if project_style is not None and (
        project.get("type") != "article" or not isinstance(project_style, str) or project_style not in ARTICLE_STYLES
    ):
        raise ConfigError(
            f"project.style is only valid for articles and must be one of: {', '.join(sorted(ARTICLE_STYLES))}"
        )

    if version == 1:
        entries = build.get("entries")
        if not isinstance(entries, Mapping) or not entries:
            raise ConfigError("build.entries must map language codes to source definitions")
        for language, entry in entries.items():
            if not isinstance(language, str) or not _LANGUAGE_CODE.fullmatch(language):
                raise ConfigError(f"invalid language identifier: {language!r}")
            if language not in languages:
                raise ConfigError(f"build.entries contains {language!r}, which is not listed in project.languages")
            if isinstance(entry, str):
                _validate_edition({"source": entry}, f"build.entries.{language}", engine)
            else:
                _validate_edition(entry, f"build.entries.{language}", engine)
    else:
        documents = config.get("documents")
        if not isinstance(documents, Mapping) or not documents:
            raise ConfigError("schema_version 2 requires a non-empty documents mapping")
        for document_id, document in documents.items():
            if not isinstance(document_id, str) or not _LANGUAGE_CODE.fullmatch(document_id):
                raise ConfigError(f"invalid document id: {document_id!r}")
            if not isinstance(document, Mapping):
                raise ConfigError(f"documents.{document_id} must be a mapping")
            document_type = document.get("type")
            if not isinstance(document_type, str) or document_type not in (PROJECT_TYPES - {"collection"}):
                raise ConfigError(
                    f"documents.{document_id}.type must be one of: {', '.join(sorted(PROJECT_TYPES - {'collection'}))}"
                )
            style = document.get("style")
            if style is not None and (
                document_type != "article" or not isinstance(style, str) or style not in ARTICLE_STYLES
            ):
                raise ConfigError(
                    f"documents.{document_id}.style is only valid for articles and must be one of: {', '.join(sorted(ARTICLE_STYLES))}"
                )
            editions = document.get("editions")
            if not isinstance(editions, Mapping) or not editions:
                raise ConfigError(f"documents.{document_id}.editions must be a non-empty mapping")
            for edition_id, edition in editions.items():
                if not isinstance(edition_id, str) or not _LANGUAGE_CODE.fullmatch(edition_id):
                    raise ConfigError(f"invalid edition id: {document_id}/{edition_id}")
                if edition_id not in languages:
                    raise ConfigError(f"documents.{document_id}.editions contains {edition_id!r}, which is not listed in project.languages")
                _validate_edition(edition, f"documents.{document_id}.editions.{edition_id}", engine)

    _safe_relative(export.get("output_dir", "build/export"), "export.output_dir")
    targets = export.get("targets", [])
    if not isinstance(targets, list) or not all(
        isinstance(x, str) and _TARGET_NAME.fullmatch(x) for x in targets
    ):
        raise ConfigError("export.targets must contain safe target identifiers")
    tag_limit = export.get("tag_limit", 5)
    if type(tag_limit) is not int or not 1 <= tag_limit <= 20:
        raise ConfigError("export.tag_limit must be an integer between 1 and 20")
    target_overrides = config.get("targets", {})
    if not isinstance(target_overrides, Mapping):
        raise ConfigError("targets must be a YAML mapping")
    for name, override in target_overrides.items():
        if not isinstance(name, str) or not _TARGET_NAME.fullmatch(name) or not isinstance(override, Mapping):
            raise ConfigError(f"targets.{name} must be a mapping with a safe identifier")
    for key in ("tags", "keywords"):
        values = project.get(key, [])
        if not isinstance(values, list) or not all(isinstance(value, str) for value in values):
            raise ConfigError(f"project.{key} must be a list of strings")


def load_config(root: str | Path = ".", config_path: str | Path | None = None,
                overrides: Mapping[str, Any] | None = None) -> dict[str, Any]:
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
