#!/usr/bin/env python3
"""Serialize YAML as base64 records for the shell loader; never emit shell code."""
from __future__ import annotations

import base64
import re
import sys
from pathlib import Path
from typing import Any

import yaml


def flatten_dict(data: dict[str, Any], parent_key: str = "", sep: str = "_") -> dict[str, str]:
    items: dict[str, str] = {}
    for key, value in data.items():
        clean_key = re.sub(r"[^A-Za-z0-9_]", "_", str(key))
        name = f"{parent_key}{sep}{clean_key}" if parent_key else clean_key
        if isinstance(value, dict):
            nested = flatten_dict(value, name, sep)
            overlap = items.keys() & nested.keys()
            if overlap:
                raise ValueError(f"duplicate flattened YAML key: {sorted(overlap)[0]}")
            items.update(nested)
        elif isinstance(value, list):
            items[name] = " ".join("" if item is None else str(item) for item in value)
        elif value is None:
            items[name] = ""
        elif isinstance(value, bool):
            items[name] = "true" if value else "false"
        else:
            items[name] = str(value)
    return items


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: parser.py <yaml_file> [prefix]", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    prefix = sys.argv[2] if len(sys.argv) > 2 else "CONFIG_"
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", prefix):
        print("Invalid variable prefix", file=sys.stderr)
        return 2
    try:
        raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    except (OSError, yaml.YAMLError) as exc:
        print(f"YAML error: {exc}", file=sys.stderr)
        return 1
    if raw is None:
        return 0
    if not isinstance(raw, dict):
        print("Top-level YAML value must be a mapping", file=sys.stderr)
        return 1
    try:
        flat = flatten_dict(raw)
    except ValueError as exc:
        print(f"YAML key error: {exc}", file=sys.stderr)
        return 1
    for key, value in flat.items():
        encoded = base64.b64encode(value.encode("utf-8")).decode("ascii")
        print(f"{prefix}{key}\t{encoded}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
