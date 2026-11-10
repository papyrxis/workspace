#!/usr/bin/env python3
"""Create and verify a deterministic downloadable Workspace release bundle."""
from __future__ import annotations

import argparse
import hashlib
import json
import zipfile
from pathlib import Path

FIXED_TIME = (1980, 1, 1, 0, 0, 0)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_bundle(source: Path, destination: Path) -> Path:
    source = source.resolve()
    destination = destination.resolve()
    if not source.is_dir():
        raise ValueError(f"distribution directory does not exist: {source}")
    artifacts = sorted(p for p in source.iterdir() if p.is_file() and p.suffix in {".whl", ".gz"})
    if not any(p.suffix == ".whl" for p in artifacts) or not any(p.name.endswith(".tar.gz") for p in artifacts):
        raise ValueError("dist/ must contain at least one wheel and one source distribution")
    entries = [{"name": p.name, "size_bytes": p.stat().st_size, "sha256": sha256(p)} for p in artifacts]
    manifest = {"manifest_version": 1, "package": "papyrxis-workspace", "artifacts": entries}
    destination.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in artifacts:
            info = zipfile.ZipInfo(f"dist/{path.name}", FIXED_TIME)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes())
        for name, data in (
            ("PACKAGE-MANIFEST.json", (json.dumps(manifest, sort_keys=True, indent=2) + "\n").encode()),
            ("SHA256SUMS", ("".join(f"{item['sha256']}  dist/{item['name']}\n" for item in entries)).encode()),
        ):
            info = zipfile.ZipInfo(name, FIXED_TIME)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data)
    verify_bundle(destination)
    return destination


def verify_bundle(bundle: Path) -> dict:
    with zipfile.ZipFile(bundle) as archive:
        bad = archive.testzip()
        if bad:
            raise ValueError(f"corrupt ZIP member: {bad}")
        manifest = json.loads(archive.read("PACKAGE-MANIFEST.json"))
        checksums = archive.read("SHA256SUMS").decode("ascii").splitlines()
        expected = {line.split("  ", 1)[1]: line.split("  ", 1)[0] for line in checksums}
        for item in manifest["artifacts"]:
            name = f"dist/{item['name']}"
            payload = archive.read(name)
            digest = hashlib.sha256(payload).hexdigest()
            if digest != item["sha256"] or digest != expected.get(name):
                raise ValueError(f"checksum mismatch: {name}")
            if len(payload) != item["size_bytes"]:
                raise ValueError(f"size mismatch: {name}")
        if len(expected) != len(manifest["artifacts"]):
            raise ValueError("checksum manifest contains unexpected or missing entries")
        return {"verified": len(manifest["artifacts"]), "manifest_version": manifest["manifest_version"]}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, default=Path("dist"))
    parser.add_argument("--output", type=Path, default=Path("dist/papyrxis-workspace-release.zip"))
    parser.add_argument("--verify", type=Path)
    args = parser.parse_args()
    if args.verify:
        result = verify_bundle(args.verify)
        print(json.dumps(result, sort_keys=True))
    else:
        result = build_bundle(args.input, args.output)
        print(f"Created and verified {result}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
