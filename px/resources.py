"""Locate packaged Workspace TeX components and construct project-first search paths."""
from __future__ import annotations

import os
import sysconfig
from pathlib import Path


def common_root() -> Path:
    """Return the shared common/ tree from a source checkout or installed wheel."""
    source_tree = Path(__file__).resolve().parents[1] / "common"
    if (source_tree / "components" / "paper-styles.tex").is_file():
        return source_tree.resolve()
    installed_tree = Path(sysconfig.get_path("data")) / "share" / "papyrxis-workspace" / "common"
    if (installed_tree / "components" / "paper-styles.tex").is_file():
        return installed_tree.resolve()
    raise FileNotFoundError(
        "Workspace common LaTeX resources are missing; reinstall the full papyrxis-workspace wheel"
    )


def tex_inputs(project_root: str | Path, source: str | Path) -> str:
    """Build TEXINPUTS with project overrides first and shared presets/components second."""
    root = Path(project_root).expanduser().resolve()
    source_path = Path(source).expanduser().resolve()
    shared = common_root()
    directories = [
        source_path.parent,
        root / "tex",
        root / "configs",
        shared.parent,
        shared,
        shared / "components",
        shared / "presets",
        shared / "packages",
    ]
    return os.pathsep.join(f"{directory}{os.sep}{os.sep}" for directory in directories) + os.pathsep
