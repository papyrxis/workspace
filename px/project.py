"""Deterministic multi-document planning, execution and artifact manifests."""
from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import tempfile
from pathlib import Path
from typing import Any

from .build import BuildError, _inside, valid_pdf
from .logger import log
from .process import run_checked

_ID = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_-]*$")
_ENGINES = {"pdflatex": "-pdf", "xelatex": "-xelatex", "lualatex": "-lualatex"}


def _documents(config: dict[str, Any]) -> dict[str, dict[str, Any]]:
    """Return a common document/edition model for v1 and v2 projects."""
    if config.get("schema_version") == 1:
        project = config["project"]
        return {
            project.get("name", "document"): {
                "type": project["type"],
                "title": project.get("title", project.get("name", "Document")),
                "editions": {
                    language: ({"source": value, "engine": config["build"].get("default_engine", "xelatex")}
                               if isinstance(value, str) else dict(value))
                    for language, value in config["build"]["entries"].items()
                },
            }
        }
    return config["documents"]


def plan_documents(root: str | Path, config: dict[str, Any], document_id: str | None = None,
                   edition: str | None = None) -> list[dict[str, Any]]:
    """Validate the complete selected build plan before any compiler is started."""
    base = Path(root).expanduser().resolve()
    output_root = _inside(base, config["build"].get("output_dir", "build"), "build.output_dir")
    if output_root == base:
        raise BuildError("build.output_dir cannot be the project root")
    documents = _documents(config)
    if document_id and document_id not in documents:
        raise BuildError(f"unknown document {document_id!r}; run px list")
    plan: list[dict[str, Any]] = []
    destinations: set[Path] = set()
    for doc_id, document in documents.items():
        if document_id and doc_id != document_id:
            continue
        if not _ID.fullmatch(doc_id):
            raise BuildError(f"invalid document id: {doc_id!r}")
        editions = document.get("editions")
        if not isinstance(editions, dict) or not editions:
            raise BuildError(f"documents.{doc_id}.editions must be a non-empty mapping")
        for edition_id, raw in editions.items():
            if edition and edition_id != edition:
                continue
            if not _ID.fullmatch(edition_id):
                raise BuildError(f"invalid edition id: {doc_id}/{edition_id}")
            if not isinstance(raw, dict) or not isinstance(raw.get("source"), str):
                raise BuildError(f"documents.{doc_id}.editions.{edition_id} requires source")
            source = _inside(base, raw["source"], f"{doc_id}/{edition_id}.source")
            if not source.is_file():
                raise BuildError(f"{doc_id}/{edition_id}: source file does not exist: {source}")
            engine = raw.get("engine", config["build"].get("default_engine", "xelatex"))
            if engine not in _ENGINES:
                raise BuildError(f"{doc_id}/{edition_id}: unsupported LaTeX engine {engine!r}")
            output_name = raw.get("output_name", source.stem)
            if not isinstance(output_name, str) or not _ID.fullmatch(output_name):
                raise BuildError(f"{doc_id}/{edition_id}: output_name must be a safe filename stem")
            output_dir = _inside(base, str(Path(config["build"].get("output_dir", "build")) / doc_id / edition_id),
                                 f"{doc_id}/{edition_id}.output")
            destination = output_dir / f"{output_name}.pdf"
            if destination in destinations:
                raise BuildError(f"output collision: multiple editions target {destination.relative_to(base)}")
            destinations.add(destination)
            plan.append({
                "document_id": doc_id, "document_type": document.get("type", config["project"]["type"]),
                "title": document.get("title", doc_id), "edition": edition_id,
                "source": source, "engine": engine, "output_dir": output_dir,
                "output": destination,
            })
    if edition and not plan:
        raise BuildError(f"edition {edition!r} is not configured for the selected document")
    if not plan:
        raise BuildError("no documents or editions selected")
    return plan


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _write_manifest(path: Path, manifest: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=".manifest-", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as stream:
            json.dump(manifest, stream, ensure_ascii=False, sort_keys=True, indent=2)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass


def build_documents(root: str | Path, config: dict[str, Any], document_id: str | None = None,
                    edition: str | None = None, *, dry_run: bool = False,
                    keep_going: bool = False) -> dict[str, Any]:
    base = Path(root).expanduser().resolve()
    plan = plan_documents(base, config, document_id, edition)
    records: list[dict[str, Any]] = []
    failures = 0
    for item in plan:
        key = f"{item['document_id']}/{item['edition']}"
        command = ["latexmk", _ENGINES[item["engine"]], "-interaction=nonstopmode", "-halt-on-error",
                   "-file-line-error", f"-outdir={item['output_dir']}", str(item["source"])]
        record = {k: item[k] for k in ("document_id", "document_type", "title", "edition", "engine")}
        record.update(source=item["source"].relative_to(base).as_posix(),
                      output=item["output"].relative_to(base).as_posix(), status="planned")
        if dry_run:
            records.append(record)
            print(" ".join(command))
            continue
        try:
            item["output_dir"].mkdir(parents=True, exist_ok=True)
            source_parent = str(item["source"].parent) + os.path.sep + os.path.sep
            env = {"TEXINPUTS": os.pathsep.join([source_parent, str(base / "tex") + os.path.sep + os.path.sep,
                                                   str(base / "configs") + os.path.sep + os.path.sep]) + os.pathsep}
            run_checked(command, cwd=base, env=env,
                        timeout=int(config["build"].get("timeout_seconds", 1800)))
            if not valid_pdf(item["output"]):
                raise BuildError(f"{key}: compiler completed but PDF is missing or invalid")
            record.update(status="success", size_bytes=item["output"].stat().st_size,
                          sha256=_sha256(item["output"]))
            log("info", f"Built {record['output']}", component="build", status="ok")
        except Exception as exc:
            failures += 1
            record.update(status="failed", error=str(exc))
            log("error", f"{key}: {exc}", component="build", status="failed")
            if not keep_going:
                records.append(record)
                break
        records.append(record)
    manifest = {
        "manifest_version": 1,
        "schema_version": config["schema_version"],
        "project": config["project"].get("name", base.name),
        "results": records,
        "summary": {"planned": len(plan), "completed": sum(r["status"] == "success" for r in records),
                    "failed": failures, "dry_run": dry_run},
    }
    if not dry_run:
        _write_manifest(base / config["build"].get("output_dir", "build") / "manifest.json", manifest)
    if failures:
        raise BuildError(f"{failures} document edition(s) failed; see build manifest")
    return manifest


def list_documents(root: str | Path, config: dict[str, Any]) -> list[dict[str, Any]]:
    base = Path(root).expanduser().resolve()
    manifest_path = base / config["build"].get("output_dir", "build") / "manifest.json"
    statuses: dict[tuple[str, str], dict[str, Any]] = {}
    if manifest_path.is_file():
        try:
            data = json.loads(manifest_path.read_text(encoding="utf-8"))
            statuses = {(r["document_id"], r["edition"]): r for r in data.get("results", [])}
        except (OSError, ValueError, KeyError, TypeError):
            log("warn", "Ignoring unreadable or invalid build manifest", component="list")
    rows = []
    for doc_id, doc in _documents(config).items():
        for edition_id, edition in doc["editions"].items():
            result = statuses.get((doc_id, edition_id), {})
            rows.append({"document_id": doc_id, "title": doc.get("title", doc_id),
                         "edition": edition_id, "source": edition.get("source", ""),
                         "status": result.get("status", "not-built"),
                         "output": result.get("output", "")})
    return rows


def verify_manifest(root: str | Path, config: dict[str, Any]) -> dict[str, Any]:
    base = Path(root).expanduser().resolve()
    manifest_path = base / config["build"].get("output_dir", "build") / "manifest.json"
    if not manifest_path.is_file():
        raise BuildError("build manifest not found; run px build first")
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise BuildError(f"cannot read build manifest: {exc}") from exc
    checked = 0
    errors = []
    for record in manifest.get("results", []):
        if record.get("status") != "success":
            errors.append(f"{record.get('document_id')}/{record.get('edition')}: status is not success")
            continue
        output = _inside(base, record.get("output", ""), "manifest output")
        if not valid_pdf(output):
            errors.append(f"{record['document_id']}/{record['edition']}: invalid PDF")
            continue
        if output.stat().st_size != record.get("size_bytes") or _sha256(output) != record.get("sha256"):
            errors.append(f"{record['document_id']}/{record['edition']}: size or SHA-256 mismatch")
            continue
        checked += 1
    if errors:
        raise BuildError("manifest verification failed: " + "; ".join(errors))
    return {"checked": checked, "manifest": manifest_path.relative_to(base).as_posix()}
