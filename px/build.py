"""Multi-language LaTeX build and PDF artifact validation."""
from __future__ import annotations

from pathlib import Path
from typing import Any, Iterable

from .logger import log
from .process import run

_ENGINE_FLAGS = {"pdflatex": "-pdf", "xelatex": "-xelatex", "lualatex": "-lualatex"}


class BuildError(RuntimeError):
    pass


def valid_pdf(path: Path) -> bool:
    try:
        size = path.stat().st_size
        with path.open("rb") as stream:
            header = stream.read(8)
            stream.seek(max(0, size - 2048))
            tail = stream.read()
        return size >= 16 and header.startswith(b"%PDF-") and b"%%EOF" in tail
    except OSError:
        return False


def _inside(root: Path, relative: str, label: str) -> Path:
    path = Path(relative)
    if path.is_absolute() or ".." in path.parts:
        raise BuildError(f"{label} must be a relative path inside the project")
    resolved = (root / path).resolve()
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise BuildError(f"{label} escapes the project directory") from exc
    return resolved


def build_project(root: str | Path, config: dict[str, Any], languages: Iterable[str] | None = None, *, dry_run: bool = False) -> list[Path]:
    base = Path(root).expanduser().resolve()
    build_cfg = config["build"]
    output_base = _inside(base, build_cfg["output_dir"], "build.output_dir")
    selected = set(languages or [])
    unknown = selected - set(build_cfg["entries"])
    if unknown:
        raise BuildError(f"language(s) not configured: {', '.join(sorted(unknown))}")
    results: list[Path] = []
    for language, raw in build_cfg["entries"].items():
        if selected and language not in selected:
            continue
        entry = {"source": raw, "engine": build_cfg.get("default_engine", "xelatex")} if isinstance(raw, str) else dict(raw)
        source = _inside(base, entry["source"], f"build.entries.{language}.source")
        engine = entry.get("engine", build_cfg.get("default_engine", "xelatex"))
        if engine not in _ENGINE_FLAGS:
            raise BuildError(f"unsupported LaTeX engine {engine!r} for {language}")
        if not source.is_file():
            raise BuildError(f"{language}: source file does not exist: {source}")
        output = output_base / language
        expected = output / f"{source.stem}.pdf"
        command = ["latexmk", _ENGINE_FLAGS[engine], "-interaction=nonstopmode", "-halt-on-error", "-file-line-error", f"-outdir={output}", str(source)]
        log("info", f"Building {language}: {source.relative_to(base)} with {engine}", component="build")
        if dry_run:
            print(" ".join(command))
            continue
        output.mkdir(parents=True, exist_ok=True)
        env = {"TEXINPUTS": f".:{base / 'tex'}//:{base / 'configs'}//:"}
        run(command, cwd=base, env=env, timeout=int(build_cfg.get("timeout_seconds", 1800)))
        if not valid_pdf(expected):
            raise BuildError(f"{language}: LaTeX command completed but PDF is missing or incomplete: {expected}")
        log("info", f"Built {expected.relative_to(base)}", component="build", status="ok")
        results.append(expected)
    return results


def clean_project(root: str | Path, config: dict[str, Any]) -> int:
    base = Path(root).expanduser().resolve()
    output = _inside(base, config["build"]["output_dir"], "build.output_dir")
    if output == base:
        raise BuildError("refusing to clean the project root")
    if not output.exists():
        return 0
    import shutil
    shutil.rmtree(output)
    log("info", f"Removed generated output {output.relative_to(base)}", component="clean")
    return 1
