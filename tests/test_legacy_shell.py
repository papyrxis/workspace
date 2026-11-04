from __future__ import annotations

import base64
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]


class LegacyYamlBoundaryTests(unittest.TestCase):
    def _write_config(self, root: Path, title: str) -> Path:
        config = root / "workspace.yml"
        config.write_text(
            yaml.safe_dump(
                {
                    "project": {"type": "article", "title": title},
                    "components": ["fonts", "paper-styles", "commands/base"],
                    "overrides": {"dir": "configs"},
                },
                allow_unicode=True,
                sort_keys=False,
            ),
            encoding="utf-8",
        )
        return config

    def test_parser_emits_base64_records_not_shell_assignments(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            marker = root / "must-not-exist"
            title = f'$(touch "{marker}") "quoted"'
            config = self._write_config(root, title)
            result = subprocess.run(
                [sys.executable, str(ROOT / "src" / "parser.py"), str(config)],
                cwd=ROOT,
                capture_output=True,
                text=True,
                check=True,
            )
            rows = dict(line.split("\t", 1) for line in result.stdout.splitlines())
            self.assertEqual(
                base64.b64decode(rows["CONFIG_project_title"]).decode("utf-8"),
                title,
            )
            self.assertEqual(
                base64.b64decode(rows["CONFIG_components"]).decode("utf-8"),
                "fonts paper-styles commands/base",
            )
            self.assertFalse(marker.exists())

    @unittest.skipIf(os.name == "nt", "Bash integration test requires POSIX")
    def test_loader_preserves_lists_and_never_executes_yaml_values(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            marker = root / "must-not-exist"
            title = f'$(touch "{marker}") "quoted"'
            config = self._write_config(root, title)
            command = (
                f'source "{ROOT / "src" / "loader.sh"}"; '
                'load_config "$1"; '
                'printf "%s\\n%s\\n%s" "$CONFIG_project_type" '
                '"$CONFIG_components" "$CONFIG_project_title"'
            )
            result = subprocess.run(
                ["bash", "-c", command, "workspace-loader-test", str(config)],
                cwd=ROOT,
                capture_output=True,
                text=True,
                check=True,
            )
            lines = result.stdout.splitlines()
            self.assertEqual(lines[0], "article")
            self.assertEqual(lines[1], "fonts paper-styles commands/base")
            self.assertEqual(lines[2], title)
            self.assertFalse(marker.exists())


if __name__ == "__main__":
    unittest.main()
