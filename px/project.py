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
from .resources import tex_inputs

_ID = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_-]*$")
_ENGINES = {"pdflatex": "-pdf", "xelatex": "-xelatex", "lualatex": "-lualatex"}


def _reject_symlink_components(root: Path, relative: str | Path, label: str) -> None:
    current = root
    for part in Path(relative).parts:
        current = current / part
        if current.is_symlink():
            raise BuildError(f"{label} must not traverse a symbolic link: {current}")


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
                   edition: str | list[str] | None = None) -> list[dict[str, Any]]:
    """Validate the complete selected build plan before any compiler is started."""
    base = Path(root).expanduser().resolve()
    output_relative = config["build"].get("output_dir", "build")
    _reject_symlink_components(base, output_relative, "build.output_dir")
    output_root = _inside(base, output_relative, "build.output_dir")
    if output_root == base:
        raise BuildError("build.output_dir cannot be the project root")
    _assert_output_does_not_contain_sources(base, output_root, config)
    documents = _documents(config)
    if document_id and document_id not in documents:
        raise BuildError(f"unknown document {document_id!r}; run px list")
    requested_editions = {edition} if isinstance(edition, str) else set(edition or [])
    seen_editions: set[str] = set()
    plan: list[dict[str, Any]] = []
    destinations: dict[str, Path] = {}
    for doc_id, document in documents.items():
        if document_id and doc_id != document_id:
            continue
        if not _ID.fullmatch(doc_id):
            raise BuildError(f"invalid document id: {doc_id!r}")
        editions = document.get("editions")
        if not isinstance(editions, dict) or not editions:
            raise BuildError(f"documents.{doc_id}.editions must be a non-empty mapping")
        for edition_id, raw in editions.items():
            if requested_editions and edition_id not in requested_editions:
                continue
            seen_editions.add(edition_id)
            if not _ID.fullmatch(edition_id):
                raise BuildError(f"invalid edition id: {doc_id}/{edition_id}")
            if not isinstance(raw, dict) or not isinstance(raw.get("source"), str):
                raise BuildError(f"documents.{doc_id}.editions.{edition_id} requires source")
            source = _inside(base, raw["source"], f"{doc_id}/{edition_id}.source")
            if not source.is_file():
                raise BuildError(f"{doc_id}/{edition_id}: source file does not exist: {source}")
            working_directory = _inside(
                base, raw.get("working_directory", "."),
                f"{doc_id}/{edition_id}.working_directory"
            )
            _reject_symlink_components(
                base,
                raw.get("working_directory", "."),
                f"{doc_id}/{edition_id}.working_directory"
            )
            if not working_directory.is_dir():
                raise BuildError(
                    f"{doc_id}/{edition_id}: working_directory does not exist or is not a directory: "
                    f"{working_directory}"
                )
            engine = raw.get("engine", config["build"].get("default_engine", "xelatex"))
            if engine not in _ENGINES:
                raise BuildError(f"{doc_id}/{edition_id}: unsupported LaTeX engine {engine!r}")
            output_name = raw.get("output_name", source.stem)
            if not isinstance(output_name, str) or not _ID.fullmatch(output_name):
                raise BuildError(f"{doc_id}/{edition_id}: output_name must be a safe filename stem")
            output_relative = Path(config["build"].get("output_dir", "build"))
            if config["schema_version"] == 2:
                output_relative = output_relative / doc_id / edition_id
            else:
                output_relative = output_relative / edition_id
            _reject_symlink_components(base, output_relative, f"{doc_id}/{edition_id}.output")
            output_dir = _inside(base, output_relative.as_posix(), f"{doc_id}/{edition_id}.output")
            destination = output_dir / f"{output_name}.pdf"
            portable_key = destination.relative_to(base).as_posix().casefold()
            if portable_key in destinations:
                raise BuildError(
                    f"output collision: {destination.relative_to(base)} conflicts with "
                    f"{destinations[portable_key].relative_to(base)} on a case-insensitive filesystem"
                )
            destinations[portable_key] = destination
            plan.append({
                "document_id": doc_id, "document_type": document.get("type", config["project"]["type"]),
                "title": document.get("title", doc_id), "edition": edition_id,
                "source": source, "engine": engine, "working_directory": working_directory,
                "output_dir": output_dir, "output": destination,
            })
    missing_editions = requested_editions - seen_editions
    if missing_editions:
        raise BuildError(f"edition(s) not configured for the selected document: {', '.join(sorted(missing_editions))}")
    if not plan:
        raise BuildError("no documents or editions selected")
    return plan


def _assert_output_does_not_contain_sources(root: Path, output_root: Path, config: dict[str, Any]) -> None:
    """Keep generated-output cleanup from removing configured source files."""
    for document_id, document in _documents(config).items():
        for edition_id, raw in document.get("editions", {}).items():
            source_value = raw if isinstance(raw, str) else raw.get("source")
            if not isinstance(source_value, str):
                continue
            source = _inside(root, source_value, f"{document_id}/{edition_id}.source")
            try:
                source.relative_to(output_root)
            except ValueError:
                continue
            raise BuildError(
                f"build.output_dir contains a configured source file ({document_id}/{edition_id}: "
                f"{source.relative_to(root).as_posix()}); choose a dedicated generated-output directory"
            )


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
                    edition: str | list[str] | None = None, *, dry_run: bool = False,
                    keep_going: bool = False) -> dict[str, Any]:
    base = Path(root).expanduser().resolve()
    plan = plan_documents(base, config, document_id, edition)
    output_root = _inside(base, config["build"].get("output_dir", "build"), "build.output_dir")
    if output_root == base:
        raise BuildError("build.output_dir cannot be the project root")
    manifest_path = output_root / "manifest.json"
    if manifest_path.is_symlink():
        raise BuildError("build manifest must not be a symbolic link")
    previous_records: list[dict[str, Any]] = []
    if not dry_run and manifest_path.is_file():
        try:
            previous_data = json.loads(manifest_path.read_text(encoding="utf-8"))
            if not isinstance(previous_data, dict):
                raise ValueError("manifest root must be an object")
            previous_records = previous_data.get("results", [])
            if not isinstance(previous_records, list) or not all(isinstance(row, dict) for row in previous_records):
                raise ValueError("results must be a list of objects")
        except (OSError, ValueError, TypeError) as exc:
            raise BuildError(f"cannot preserve previous build manifest: {exc}") from exc
    selected_keys = {(item["document_id"], item["edition"]) for item in plan}
    expected_keys = {
        (doc_id, edition_id)
        for doc_id, document in _documents(config).items()
        for edition_id in document["editions"]
    }
    records: list[dict[str, Any]] = []
    failures = 0
    for item in plan:
        key = f"{item['document_id']}/{item['edition']}"
        command = ["latexmk", _ENGINES[item["engine"]], "-interaction=nonstopmode", "-halt-on-error",
                   "-file-line-error", f"-jobname={item['output'].stem}", f"-outdir={item['output_dir']}", str(item["source"])]
        record = {k: item[k] for k in ("document_id", "document_type", "title", "edition", "engine")}
        record.update(source=item["source"].relative_to(base).as_posix(),
                      source_sha256=_sha256(item["source"]),
                      working_directory=item["working_directory"].relative_to(base).as_posix(),
                      output=item["output"].relative_to(base).as_posix(), status="planned")
        if dry_run:
            records.append(record)
            print(" ".join(command))
            continue
        try:
            item["output_dir"].mkdir(parents=True, exist_ok=True)
            env = {"TEXINPUTS": tex_inputs(base, item["source"])}
            run_checked(command, cwd=item["working_directory"], env=env,
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
    if dry_run:
        all_records = records
    else:
        preserved = [
            row for row in previous_records
            if (row.get("document_id"), row.get("edition")) not in selected_keys
            and (row.get("document_id"), row.get("edition")) in expected_keys
        ]
        all_records = preserved + records
        all_records.sort(key=lambda row: (row.get("document_id", ""), row.get("edition", "")))
    completed = sum(row.get("status") == "success" for row in all_records)
    failed_total = sum(row.get("status") == "failed" for row in all_records)
    manifest = {
        "manifest_version": 1,
        "schema_version": config["schema_version"],
        "project": config["project"].get("name", base.name),
        "results": all_records,
        "summary": {"planned": len(expected_keys), "attempted": len(records),
                    "completed": completed, "failed": failed_total,
                    "pending": max(0, len(expected_keys) - len(all_records)), "dry_run": dry_run},
    }
    if not dry_run:
        _write_manifest(manifest_path, manifest)
    if failures:
        raise BuildError(f"{failures} document edition(s) failed; see build manifest")
    return manifest


def list_documents(root: str | Path, config: dict[str, Any]) -> list[dict[str, Any]]:
    base = Path(root).expanduser().resolve()
    output_relative = config["build"].get("output_dir", "build")
    _reject_symlink_components(base, output_relative, "build.output_dir")
    output_root = _inside(base, output_relative, "build.output_dir")
    if output_root == base:
        raise BuildError("build.output_dir cannot be the project root")
    manifest_path = output_root / "manifest.json"
    if manifest_path.is_symlink():
        raise BuildError("build manifest must not be a symbolic link")
    statuses: dict[tuple[str, str], dict[str, Any]] = {}
    if manifest_path.is_file():
        try:
            data = json.loads(manifest_path.read_text(encoding="utf-8"))
            if not isinstance(data, dict) or not isinstance(data.get("results", []), list):
                raise ValueError("invalid manifest structure")
            statuses = {(r["document_id"], r["edition"]): r for r in data.get("results", [])}
        except (OSError, ValueError, KeyError, TypeError):
            log("warn", "Ignoring unreadable or invalid build manifest", component="list")
    rows = []
    for doc_id, doc in _documents(config).items():
        for edition_id, edition in doc["editions"].items():
            result = statuses.get((doc_id, edition_id), {})
            source = edition if isinstance(edition, str) else edition.get("source", "")
            rows.append({"document_id": doc_id, "title": doc.get("title", doc_id),
                         "edition": edition_id, "source": source,
                         "status": result.get("status", "not-built"),
                         "output": result.get("output", "")})
    return rows


def verify_manifest(root: str | Path, config: dict[str, Any]) -> dict[str, Any]:
    base = Path(root).expanduser().resolve()
    output_relative = config["build"].get("output_dir", "build")
    _reject_symlink_components(base, output_relative, "build.output_dir")
    output_root = _inside(base, output_relative, "build.output_dir")
    if output_root == base:
        raise BuildError("build.output_dir cannot be the project root")
    manifest_path = output_root / "manifest.json"
    if manifest_path.is_symlink():
        raise BuildError("build manifest must not be a symbolic link")
    if not manifest_path.is_file():
        raise BuildError("build manifest not found; run px build first")
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise BuildError(f"cannot read build manifest: {exc}") from exc
    if not isinstance(manifest, dict) or manifest.get("schema_version") != config["schema_version"]:
        raise BuildError("build manifest schema does not match the project configuration")
    results = manifest.get("results")
    if not isinstance(results, list) or not results or not all(isinstance(row, dict) for row in results):
        raise BuildError("build manifest must contain a non-empty list of artifact result objects")
    by_key = {(row.get("document_id"), row.get("edition")): row for row in results}
    if len(by_key) != len(results):
        raise BuildError("build manifest contains duplicate document/edition records")
    expected = plan_documents(base, config)
    expected_keys = {(item["document_id"], item["edition"]) for item in expected}
    errors = []
    for unexpected in set(by_key) - expected_keys:
        errors.append(f"{unexpected[0]}/{unexpected[1]}: unexpected manifest entry")
    for item in expected:
        key = (item["document_id"], item["edition"])
        if key not in by_key:
            errors.append(f"{key[0]}/{key[1]}: missing from build manifest")
    checked = 0
    for record in results:
        if record.get("status") != "success":
            errors.append(f"{record.get('document_id')}/{record.get('edition')}: status is not success")
            continue
        output = _inside(base, record.get("output", ""), "manifest output")
        if not valid_pdf(output):
            errors.append(f"{record['document_id']}/{record['edition']}: invalid PDF")
            continue
        source = _inside(base, record.get("source", ""), "manifest source")
        if not source.is_file() or _sha256(source) != record.get("source_sha256"):
            errors.append(f"{record['document_id']}/{record['edition']}: source changed since build")
            continue
        if output.stat().st_size != record.get("size_bytes") or _sha256(output) != record.get("sha256"):
            errors.append(f"{record['document_id']}/{record['edition']}: size or SHA-256 mismatch")
            continue
        checked += 1
    if errors:
        raise BuildError("manifest verification failed: " + "; ".join(errors))
    return {"checked": checked, "manifest": manifest_path.relative_to(base).as_posix()}


def clean_document(root: str | Path, config: dict[str, Any], document_id: str,
                   edition: str | None = None) -> None:
    """Remove one v2 document, or one of its editions, and reconcile the manifest."""
    if config.get("schema_version") != 2:
        raise BuildError("selective clean requires schema_version 2")
    base = Path(root).expanduser().resolve()
    documents = _documents(config)
    if document_id not in documents:
        raise BuildError(f"unknown document {document_id!r}; run px list")
    configured_editions = documents[document_id]["editions"]
    if edition is not None and edition not in configured_editions:
        raise BuildError(
            f"unknown edition {edition!r} for {document_id}; "
            f"configured editions: {', '.join(configured_editions)}"
        )
    output_relative = config["build"].get("output_dir", "build")
    target_relative = Path(output_relative) / document_id
    if edition is not None:
        target_relative /= edition
    _reject_symlink_components(base, output_relative, "build.output_dir")
    _reject_symlink_components(base, target_relative, "clean target")
    output_root = _inside(base, output_relative, "build.output_dir")
    target = _inside(base, target_relative.as_posix(), "clean target")
    if target == base or target == output_root:
        raise BuildError("refusing to clean project root or shared build directory")
    _assert_output_does_not_contain_sources(base, output_root, config)
    manifest_path = output_root / "manifest.json"
    manifest = None
    if manifest_path.is_symlink():
        raise BuildError("build manifest must not be a symbolic link")
    if manifest_path.is_file():
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            if not isinstance(manifest, dict) or not isinstance(manifest.get("results", []), list):
                raise ValueError("invalid manifest structure")
            if not all(isinstance(row, dict) for row in manifest.get("results", [])):
                raise ValueError("manifest results must be objects")
        except (OSError, ValueError) as exc:
            raise BuildError(f"cannot reconcile build manifest before clean: {exc}") from exc
    if target.exists():
        if not target.is_dir():
            raise BuildError(f"refusing to remove non-directory build output: {target}")
        shutil.rmtree(target)
    if manifest is not None:
        manifest["results"] = [
            row for row in manifest.get("results", [])
            if not (
                row.get("document_id") == document_id
                and (edition is None or row.get("edition") == edition)
            )
        ]
        expected_remaining = sum(
            len(document["editions"])
            for key, document in documents.items()
            if key != document_id
        )
        if edition is not None:
            expected_remaining += len(configured_editions) - 1
        completed = sum(row.get("status") == "success" for row in manifest["results"])
        failed = sum(row.get("status") == "failed" for row in manifest["results"])
        manifest["summary"] = {
            "planned": expected_remaining,
            "attempted": len(manifest["results"]),
            "completed": completed,
            "failed": failed,
            "pending": max(0, expected_remaining - len(manifest["results"])),
            "dry_run": False,
        }
        _write_manifest(manifest_path, manifest)
    label = f"{document_id}/{edition}" if edition is not None else document_id
    log("info", f"Removed generated output for {label}", component="clean", status="ok")

