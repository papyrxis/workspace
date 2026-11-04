"""Pandoc-based Markdown export with optional CSL and target-specific front matter."""
from __future__ import annotations

from pathlib import Path
from typing import Any

from .logger import log
from .process import run_checked
from .tags import generate_tags
from .targets import resolve_target


class ExportError(RuntimeError):
    pass


def _inside(root: Path, value: str, label: str) -> Path:
    path = Path(value)
    if path.is_absolute() or ".." in path.parts:
        raise ExportError(f"{label} must stay inside the project")
    resolved = (root / path).resolve()
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise ExportError(f"{label} escapes the project directory") from exc
    return resolved


def export_project(root: str | Path, config: dict[str, Any], target_names: list[str] | None = None) -> list[Path]:
    base = Path(root).expanduser().resolve()
    export_cfg = config["export"]
    names = target_names or export_cfg.get("targets", ["devto"])
    output_base = _inside(base, export_cfg["output_dir"], "export.output_dir")
    outputs: list[Path] = []
    for target_name in names:
        target = resolve_target(target_name, config.get("targets", {}))
        for language, raw in config["build"]["entries"].items():
            entry = {"source": raw} if isinstance(raw, str) else raw
            source = _inside(base, entry["source"], f"build.entries.{language}.source")
            if not source.is_file():
                raise ExportError(f"export source does not exist: {source}")
            destination = output_base / language / f"{source.stem}-{target_name}.md"
            destination.parent.mkdir(parents=True, exist_ok=True)
            command = ["pandoc", str(source), "--from=latex", f"--to={target['format']}", "--wrap=none"]
            bibliography = config.get("bibliography", {}).get("file")
            if bibliography:
                bib_path = _inside(base, bibliography, "bibliography.file")
                if not bib_path.is_file():
                    raise ExportError(f"bibliography file does not exist: {bib_path}")
                command.append(f"--bibliography={bib_path}")
            csl = target.get("csl")
            if csl:
                csl_path = Path(csl)
                if not csl_path.is_absolute():
                    project_path = (base / csl_path).resolve()
                    csl_path = project_path if base in project_path.parents else Path(__file__).resolve().parents[1] / csl_path
                if not csl_path.is_file():
                    raise ExportError(f"CSL file requested by {target_name!r} does not exist: {csl_path}")
                command.extend(["--citeproc", f"--csl={csl_path}"])
            for filter_path in target.get("filters", []):
                path = _inside(base, filter_path, f"targets.{target_name}.filters")
                if not path.is_file():
                    raise ExportError(f"Pandoc filter does not exist: {path}")
                command.append(f"--lua-filter={path}")
            command.extend(["--output", str(destination)])
            log("info", f"Exporting {language} for {target_name}", component="export")
            run_checked(command, cwd=base, timeout=900)
            if target.get("front_matter"):
                project = config["project"]
                values = list(project.get("tags", [])) + list(project.get("keywords", []))
                tags = generate_tags(values, min(int(target.get("max_tags", 5)), int(export_cfg.get("tag_limit", 5))))
                title = str(project.get("title", "")).replace('"', "'")
                front = ["---", f'title: "{title}"', "published: false", "tags: [" + ", ".join(tags) + "]", "---", ""]
                body = destination.read_text(encoding="utf-8")
                destination.write_text("\n".join(front) + body, encoding="utf-8")
            outputs.append(destination)
    return outputs
