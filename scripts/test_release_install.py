#!/usr/bin/env python3
"""Install the wheel from a release bundle in an isolated venv and smoke-test px."""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
import venv
import zipfile
from pathlib import Path, PurePosixPath

from package_release import verify_bundle


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--project-example", type=Path, default=Path("examples/multi-document"))
    args = parser.parse_args()
    bundle = args.bundle.resolve()
    verify_bundle(bundle)
    with tempfile.TemporaryDirectory(prefix="px-install-e2e-") as temporary:
        root = Path(temporary)
        extracted = root / "bundle"
        extracted.mkdir()
        with zipfile.ZipFile(bundle) as archive:
            for member in archive.infolist():
                relative = PurePosixPath(member.filename)
                if relative.is_absolute() or ".." in relative.parts:
                    raise SystemExit(f"unsafe bundle path: {member.filename}")
                destination = extracted.joinpath(*relative.parts)
                if member.is_dir():
                    destination.mkdir(parents=True, exist_ok=True)
                else:
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    with archive.open(member) as reader, destination.open("xb") as writer:
                        writer.write(reader.read())
        wheels = sorted((extracted / "dist").glob("*.whl"))
        if len(wheels) != 1:
            raise SystemExit(f"expected exactly one wheel, found {len(wheels)}")
        environment = root / "venv"
        venv.EnvBuilder(with_pip=True).create(environment)
        python = environment / ("Scripts/python.exe" if os.name == "nt" else "bin/python")
        px = environment / ("Scripts/px.exe" if os.name == "nt" else "bin/px")
        subprocess.run([str(python), "-m", "pip", "install", str(wheels[0])], check=True)
        subprocess.run([str(python), "-c", "from px.resources import common_root; p=common_root(); assert (p / 'components' / 'paper-styles.tex').is_file(); assert (p / 'presets' / 'book' / 'technical.tex').is_file()"], check=True)
        subprocess.run([str(px), "--help"], check=True, stdout=subprocess.DEVNULL)
        example = args.project_example.resolve()
        subprocess.run([str(px), "--root", str(example), "list", "--json"], check=True,
                       stdout=subprocess.DEVNULL)
    print("Release bundle installation and px CLI smoke test passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
